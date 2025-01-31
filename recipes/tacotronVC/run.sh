#!/bin/bash

set -e
set -u
set -o pipefail

function xrun () {
    set -x
    $@
    set +x
}

script_dir=$(cd $(dirname ${BASH_SOURCE:-$0}); pwd)
COMMON_ROOT=../common
. $COMMON_ROOT/yaml_parser.sh || exit 1;

eval $(parse_yaml "./config.yaml" "")

train_set="train"
dev_set="dev"
eval_set="eval"
datasets=($train_set $dev_set $eval_set)
testsets=($eval_set)

stage=0
stop_stage=0

. $COMMON_ROOT/parse_options.sh || exit 1;

dumpdir=dump
dump_org_dir=$dumpdir/${spk}_sr${sample_rate}/org
dump_norm_dir=$dumpdir/${spk}_sr${sample_rate}/norm

# exp name
if [ -z ${tag:=} ]; then
    expname=${spk}_sr${sample_rate}
else
    expname=${spk}_sr${sample_rate}_${tag}
fi
expdir=exp/$expname
# configを残しておく.
mkdir -p $expdir
mkdir -p $expdir/conf
cp ./config.yaml $expdir

if [ ${stage} -le -1 ] && [ ${stop_stage} -ge -1 ]; then
    echo "stage -1: Data download"
    mkdir -p downloads
    if [ ! -d downloads/jsut_ver1.1 ]; then
        cd downloads
        curl -LO http://ss-takashi.sakura.ne.jp/corpus/jsut_ver1.1.zip
        unzip -o jsut_ver1.1.zip
        cd -
    fi
    if [ ! -d downloads/jsss_ver1 ]; then
        cd downloads
        FILE_ID=1NyiZCXkYTdYBNtD1B-IMAYCVa-0SQsKX
        FILE_NAME=jsss_ver1.zip
        curl -sc /tmp/cookie "https://drive.google.com/uc?export=download&id=${FILE_ID}" > /dev/null
        CODE="$(awk '/_warning_/ {print $NF}' /tmp/cookie)"  
        curl -Lb /tmp/cookie "https://drive.google.com/uc?export=download&confirm=${CODE}&id=${FILE_ID}" -o ${FILE_NAME}
        unzip -o jsss_ver1.zip
        cd -
    fi
    xrun python rawdata_preprocess.py \
    jsut jsss downloads/jsut_ver1.1 downloads/jsss_ver1 \
    --output_root downloads/
fi

if [ ${stage} -le 0 ] && [ ${stop_stage} -ge 0 ]; then
    echo "stage 0: Data preparation"
    echo "train/dev/eval split"
    mkdir -p data
    find $src_wav_root -name "*.wav" -exec basename {} .wav \; | shuf > data/utt_list.txt
    head -n $train_num data/utt_list.txt > data/train.list
    tail -$deveval_num data/utt_list.txt > data/deveval.list
    head -n $dev_num data/deveval.list > data/dev.list
    tail -n $eval_num data/deveval.list > data/eval.list
    rm -f data/deveval.list
fi

if [ ${stage} -le 1 ] && [ ${stop_stage} -ge 1 ]; then
    echo "stage 1: Feature generation for tacotron2VC"
    for s in ${datasets[@]}; do
        xrun python preprocess.py data/$s.list $src_wav_root $tgt_wav_root \
            $dump_org_dir/$s --n_jobs $n_jobs --sample_rate $sample_rate \
            --silence_thresh_h $silence_thresh_h --silence_thresh_t $silence_thresh_t \
            --chunk_size $chunk_size --filter_length $filter_length \
            --hop_length $hop_length --win_length $win_length \
            --n_mel_channels $n_mel_channels --mel_fmin $mel_fmin --mel_fmax $mel_fmax \
            --clip $clip --log_base $log_base
    done
    # preprocess実行時にのみcopyするようにする.
    mkdir -p $expdir/data
    cp -r data/*.list $expdir/data/
fi

if [ ${stage} -le 2 ] && [ ${stop_stage} -ge 2 ]; then
    echo "stage 2: feature normalization"
    for typ in "tacotron2VC"; do
       for inout in "in" "out"; do
            xrun python $COMMON_ROOT/fit_scaler.py data/train.list \
                $dump_org_dir/$train_set/${inout}_${typ} \
                $dump_org_dir/${inout}_${typ}_scaler.joblib
        done
    done

    mkdir -p $dump_norm_dir
    cp -v $dump_org_dir/*.joblib $dump_norm_dir/

    for s in ${datasets[@]}; do
        for typ in "tacotron2VC"; do
            for inout in "out" "in"; do
                xrun python $COMMON_ROOT/preprocess_normalize.py data/$s.list \
                    $dump_org_dir/${inout}_${typ}_scaler.joblib \
                    $dump_org_dir/$s/${inout}_${typ} \
                    $dump_norm_dir/$s/${inout}_${typ} --n_jobs $n_jobs
            done
        done
    done
fi

if [ ${stage} -le 3 ] && [ ${stop_stage} -ge 3 ]; then
    echo "stage 3: finetuning hifigan"
    xrun python train_hifigan.py model=$vocoder_model tqdm=$tqdm \
        cudnn.benchmark=$cudnn_benchmark cudnn.deterministic=$cudnn_deterministic \
        data.train.utt_list=data/train.list \
        data.train.in_dir=$tgt_wav_root \
        data.dev.utt_list=data/dev.list \
        data.dev.in_dir=$tgt_wav_root \
        data.batch_size=$hifigan_data_batch_size \
        data.sampling_rate=$sample_rate \
        data.n_fft=$filter_length \
        data.num_mels=$n_mel_channels \
        data.hop_size=$hop_length \
        data.win_size=$win_length \
        data.fmin=$mel_fmin \
        data.fmax=$mel_fmax \
        train.out_dir=$expdir/${vocoder_model} \
        train.log_dir=tensorboard/${expname}_${vocoder_model} \
        train.nepochs=$hifigan_train_nepochs

    # save config
    cp -r conf/train_hifigan $expdir/conf
fi

if [ ${stage} -le 4 ] && [ ${stop_stage} -ge 4 ]; then
    echo "stage 4: Training tacotron2VC"
    xrun python train_tacotron2VC.py model=$acoustic_model tqdm=$tqdm \
        cudnn.benchmark=$cudnn_benchmark cudnn.deterministic=$cudnn_deterministic \
        data.train.utt_list=data/train.list \
        data.train.in_dir=$dump_norm_dir/$train_set/in_tacotron2VC/ \
        data.train.out_dir=$dump_norm_dir/$train_set/out_tacotron2VC/ \
        data.dev.utt_list=data/dev.list \
        data.dev.in_dir=$dump_norm_dir/$dev_set/in_tacotron2VC/ \
        data.dev.out_dir=$dump_norm_dir/$dev_set/out_tacotron2VC/ \
        data.batch_size=$tacotron2_data_batch_size \
        train.out_dir=$expdir/${acoustic_model} \
        train.log_dir=tensorboard/${expname}_${acoustic_model} \
        train.nepochs=$tacotron2_train_nepochs \
        train.sampling_rate=$sample_rate \
        train.mel_scaler_path=$dump_norm_dir/out_tacotron2VC_scaler.joblib \
        train.vocoder_name=$vocoder_model \
        train.vocoder_config=$vocoder_config \
        train.vocoder_weight_path=$vocoder_weight_base_path/$vocoder_eval_checkpoint \
        model.netG.n_mel_channel=$n_mel_channels \
        model.netG.reduction_factor=$reduction_factor
    
    # save config
    cp -r conf/train_tacotron2VC $expdir/conf
fi

if [ ${stage} -le 5 ] && [ ${stop_stage} -ge 5 ]; then
    echo "stage 5: Synthesis waveforms by hifigan"
    for s in ${testsets[@]}; do
        xrun python synthesis.py utt_list=./data/$s.list tqdm=$tqdm \
            in_dir=$dump_norm_dir/$s/in_tacotron2VC \
            out_mel_dir=$dump_norm_dir/$s/out_tacotron2VC/mel \
            out_dir=$expdir/synthesis_${acoustic_model}_${vocoder_model}/$s \
            sample_rate=$sample_rate \
            acoustic.checkpoint=$expdir/${acoustic_model}/$acoustic_eval_checkpoint \
            acoustic.out_scaler_path=$dump_norm_dir/out_tacotron2VC_mel_scaler.joblib \
            acoustic.model_yaml=$expdir/${acoustic_model}/model.yaml \
            vocoder.checkpoint=$vocoder_weight_base_path/$vocoder_eval_checkpoint \
            vocoder.model_yaml=$vocoder_config \
            reverse=$reverse num_eval_utts=$num_eval_utts
    done
    # save config
    cp -r conf/synthesis $expdir/conf
fi

if [ ${stage} -le 90 ] && [ ${stop_stage} -ge 90 ]; then
    echo "Tuning tacotron2VC by optuna"
    mkdir -p $expdir/${acoustic_model}

    xrun python tuning_tacotron2VC.py model=$acoustic_model tqdm=$tqdm \
        tuning=$tuning_config tuning.study_name=$expname\
        tuning.storage=sqlite:///../../../${expdir}/${acoustic_model}/optuna_study.db \
        cudnn.benchmark=$cudnn_benchmark cudnn.deterministic=$cudnn_deterministic \
        data.train.utt_list=data/train.list \
        data.train.in_dir=$dump_norm_dir/$train_set/in_tacotron2VC/ \
        data.train.out_dir=$dump_norm_dir/$train_set/out_tacotron2VC/ \
        data.dev.utt_list=data/dev.list \
        data.dev.in_dir=$dump_norm_dir/$dev_set/in_tacotron2VC/ \
        data.dev.out_dir=$dump_norm_dir/$dev_set/out_tacotron2VC/ \
        data.batch_size=$tacotron2_data_batch_size \
        data.sentence_duration=$sentence_duration \
        train.out_dir=$expdir/${acoustic_model} \
        train.log_dir=tensorboard/${expname}_${acoustic_model} \
        train.nepochs=$tacotron2_train_nepochs \
        train.sampling_rate=$sample_rate \
        train.mel_scaler_path=$dump_norm_dir/out_tacotron2VC_mel_scaler.joblib \
        train.vocoder_name=$vocoder_model \
        train.vocoder_config=$vocoder_config \
        train.vocoder_weight_path=$vocoder_weight_base_path/$vocoder_eval_checkpoint \
        model.netG.n_mel_channel=$n_mel_channels \
        model.netG.reduction_factor=$reduction_factor
    # save config
    cp -r conf/train_tacotron2VC $expdir/conf
fi

if [ ${stage} -le 98 ] && [ ${stop_stage} -ge 98 ]; then
    echo "Pack models for VC"
    dst_dir=tts_models/${expname}_${acoustic_model}_${vocoder_model}
    mkdir -p $dst_dir

    # global config
    cat > ${dst_dir}/config.yaml <<EOL
sample_rate: ${sample_rate}
acoustic_model: ${acoustic_model}
vocoder_model: ${vocoder_model}

filter_length: ${filter_length}
hop_length: ${hop_length}
win_length: ${win_length}
n_mel_channels: ${n_mel_channels}
mel_fmin: ${mel_fmin}
mel_fmax: ${mel_fmax}
clip: ${clip}
log_base: ${log_base}
is_continuous_pitch: ${is_continuous_pitch}
EOL

    # Stats
    python $COMMON_ROOT/scaler_joblib2npy.py $dump_norm_dir/in_tacotron2VC_energy_scaler.joblib $dst_dir
    python $COMMON_ROOT/scaler_joblib2npy.py $dump_norm_dir/in_tacotron2VC_mel_scaler.joblib $dst_dir
    python $COMMON_ROOT/scaler_joblib2npy.py $dump_norm_dir/in_tacotron2VC_pitch_scaler.joblib $dst_dir
    python $COMMON_ROOT/scaler_joblib2npy.py $dump_norm_dir/out_tacotron2VC_mel_scaler.joblib $dst_dir

    # Acoustic model
    python $COMMON_ROOT/clean_checkpoint_state.py $expdir/${acoustic_model}/$acoustic_eval_checkpoint \
        $dst_dir/acoustic_model.pth
    cp $expdir/${acoustic_model}/model.yaml $dst_dir/acoustic_model.yaml

    # vocoder
    python $COMMON_ROOT/clean_checkpoint_state.py $vocoder_weight_base_path/$vocoder_eval_checkpoint \
        $dst_dir/vocoder_model.pth
    cp $vocoder_weight_base_path/model.yaml $dst_dir/vocoder_model.yaml

    # make tar.gz
    rm -rf tmp
    mkdir -p tmp/${export_model_name}
    rsync -avr $dst_dir/* tmp/${export_model_name}
    cd tmp
    tar czvf ${export_model_name}.tar.gz ${export_model_name}
    mv ${export_model_name}.tar.gz ..
    cd -
    rm -rf tmp

    echo "All the files are ready for VC!"
    echo "Please check the $dst_dir directory"
fi

if [ ${stage} -le 99 ] && [ ${stop_stage} -ge 99 ]; then
    echo "Create tar.gz to share experiments"
    rm -rf tmp/exp
    mkdir -p tmp/exp/$expname
    rsync -avr $expdir/$acoustic_model tmp/exp/$expname/ --exclude "epoch*.pth"
    rsync -avr $vocoder_weight_base_path tmp/exp/$expname/ --exclude "epoch*.pth"
    rsync -avr $expdir/synthesis_${acoustic_model}_${vocoder_model} tmp/exp/$expname/ --exclude "epoch*.pth"
    cd tmp
    tar czvf tacotron2VC_exp.tar.gz exp/
    mv tacotron2VC_exp.tar.gz ..
    cd -
    rm -rf tmp
    echo "Please check tacotron2VC_exp.tar.gz"
fi
