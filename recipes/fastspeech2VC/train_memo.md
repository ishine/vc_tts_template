# train_memo
今まで同様に, trainの詳細をここに記載しておく.

- spk
    - jsut_jsss
        - 最初の.
        - pitchの実装をミスってしまい, 0になっているやつ
    
    - jsut_jsss_1
        - ↑を修正したもの

    - N2C
        - N2C初回.
    
    - jsut_jsss_jvs
        - 上に書いてあるコーパスすべてのVC. multi.
        - pretrain用.
    
    - N2C_2
        - sent_durationを実装して再実行.
        - min_silence_len: 500
    
    - N2C_3
        - min_silence_len: 100にして再度実行.
    
    - N2C_4
        - silence_thresh_t: -100にして再実行.
            - N2C_2で結果が出ない原因はこいつだった.
        - min_silence_len: 500
    - N2C_5
        - silence_thresh_t: -100
        - min_silence_len: 500
        - reduction_factor: 1
    - N2C_6
        - silence_thresh_t: -100
        - min_silence_len: 500
        - reduction_factor: 3
        - **ここから, durationの計算方法が変更. よりよいモノに**
        - その際に, このアルゴでも計算を失敗するような音声が見つかる
            - 目視・聴覚検査の結果, もうデータ側の問題と判断し, 削除
            - 削除リストは以下
                - `n_c_memory_1-04.wav`
        - プロダクトの時もこれは気を付けた方が良さそう.
    - N2C_7
        - silence_thresh_t: -100
        - min_silence_len: 500
        - reduction_factor: 3
        - N2C_6でなぜか80melで計算して爆死していたので, 20に戻して再挑戦.
    - N2C_8
        - silence_thresh_t: -100
        - min_silence_len: 500
        - reduction_factor: 3
        - durationをTacotron2のteacher forcingによって計算してみる.
    - N2C_9
        - silence_thresh_t: -100
        - min_silence_len: 50
        - reduction_factor: 3
        - durationをTacotron2のteacher forcingによって計算してみた.
    - N2C_10
        - silence_thresh_t: -100
        - min_silence_len: 200
        - reduction_factor: 3
        - 適度なmin_silence_lenでやったらどうなるのか見てみる.
    - JSUT_NICT_LINE
        - silence_thresh_t: -100
        - min_silence_len: 50
        - reduction_factor: 3
        - 全部乗せ. 一部長すぎる発話はメモリに乗らなくなるのを防ぐために除去した. 一番下に乗せておく.
    - JSUT_NICT_LINE_2
        - silence_thresh_t: -100
        - min_silence_len: 200
        - reduction_factor: 3
        - 一応min_silence_len: 200でも試してみる.

- tag
    - jsut_jsss_1
        - spk: jsut_jsss
    
    - jsut_jsss_2
        - spk: jsut_jsss_1
        - pitchを修正して初挑戦
    
    - N2C_1
        - spk: N2C
        - pretrain: jsut_jsss_2
    
    - jsut_jsss_jvs_1
        - spk: jsut_jsss_jvs
        - pretrain用.

    - N2C_2
        - spk: N2C
        - pretrian: jsut_jsss_jvs_1

    - N2C_3
        - spk: N2C
        - pretrain: なし
        - VariancePridicterでreduction factorの実装ミスっていた説があるので実行しなおし.
    
    - N2C_4
        - spk: N2C
        - pretrain: なし
        - pitchのAR化を実装した.
    
    - N2C_5
        - spk: N2C_2
        - pretrain: なし
        - wGMM
    - N2C_6
        - spk: N2C_2
        - pretrain: なし
        - wGMM, optuna
    - N2C_7
        - spk: N2C_2
        - pretrain: なし
        - wGMM, optuna, パラメタめちゃ少な目
    - N2C_8
        - spk: N2C_2
        - pretrain: なし
        - wGMM, optunaでよかったパラメタで訓練チャレンジ.
        - 結果、ダメダメ. mel以外の指標が死んでいた...ちゃんと全部のlossでやりたいが, betaを固定するのは悪手そう...
    - N2C_9
        - spk: N2C_2
        - pretrain: なし
        - wGMM, よさげなパラメタ(論文に似せている)で再挑戦. ← N2C_5と同じパラメタだった...。
    - N2C_10
        - spk: N2C_2
        - pretrain: なし
        - N2C_9において、lrがおかしいことになっていた(warmupのせいで、あほみたいに大きなlrになる問題が発生していた).
            - なので, batch_sizeを戻して実験.
        - 結果はまぁpitchARのみよりlossは悪化. 一方で、感情は少しだけ取り戻している?
    - N2C_11
        - spk: N2C_2
        - pretrain: なし
        - optunaリベンジ. lr問題を修正したうえで、更に基準を一番大事なpitch lossにしてみた.
            - #3が一番落ち着いている推移をしているので#3でしっかり訓練してみる.
    - N2C_12
        - spk: N2C_2
        - pretrain: なし
        - N2C_10で探索した#3で訓練.
            - ダメダメだった. 普通にやっぱりpitchで探すのは無理だった.
    - N2C_13
        - spk: N2C_2
        - pretrain: なし
        - lr_schedulerを直した後、pitchで探索したが, 素直にpost mel lossで探索する.
    - N2C_14
        - spk: N2C_3
        - pretrain: なし
        - min_silence_lenを小さくして、sentence_levelだったものを細かくしてみてoptuna挑戦. 果たしてどうなるか.
    - N2C_15
        - spk: N2C_3
        - pretrain: なし
        - N2C_14でみつけた、#53
            - 微妙かも. まぁそれ以上にwGMM自体が微妙
            - まずは, pretrainしてある程度学習が進んでからの方がよいのでは???
            - min_silence_lenを500に戻し, そのうえでpretrainから始めてみる.
    - N2C_16
        - spk: N2C_2
        - pretrain: なし
        - pretrain用. pitchARのみ.
            - もちろんsetntence_duration: 0
        - warmup rateのミスが発覚.
            - group_sizeは計算に入っているのだから、倍率に影響しない.
            - batch_sizeのみ考えて割り算するべきだった.
    - N2C_17
        - spk: N2C_2
        - pretrain: なし
        - 実行時間: 32min/50epoch
        - pretrainやり直し.
        - なぜか再現が出来ない...。warm_up_rateもちゃんと1000にしているのにもかかわらず...。
            - 少量データセットには小さいbatchの方がいいのかもしれません.
    - N2C_18
        - spk: N2C_2
        - pretrain: なし
        - 実行時間: 26min/22epoch
        - pretrainやり直し.
        - N2C_17で過去の結果であるN2C_4を再現できなかったので, batch_sizeを小さくしてみる. その代わり、group_sizeを64にしてみる.
    - N2C_19
        - spk: N2C_2
        - pretrain: なし
        - 実行時間: 33min/23epoch
        - pretrainやり直し.
        - なぜかN2C_18では再現できなかった。。。。
            - trainも中途半端だし.
            - 違う点
                - group_size
                    - むしろ改善すると思ったが...。
                - spk
                    - たぶんほぼ同じなのに...。
                - モデルの実装
                    - 見え方変えただけだけど.
            - まずはgroup_size=4にしてちゃんとやってみる.
            - これで無理ならspkもN2Cに戻す.
	- ダメでした 次はspkを1に戻します.
    - N2C_20
        - spk: N2C
        - pretrain: なし
        - 実行時間: 
        - pretrainやり直し.
        - これでだめなら、違うところはもう初期値とかモデルの書き換え時のミスとかしかなくなってくる.
        - 再現成功！！！！！！データセット側の問題だった！！！
            - 変更したところ: silence_thresh_t = -100 → -80
        - ↑これを確かめるために, -100にして, sentence_durationも作り直してみる.
    - N2C_21
        - spk: N2C_4
        - pretrain: なし
        - 実行時間: /50epoch
        - silence_t=-100にして, ちゃんと仮説↑が正しかったかを確かめる.
        - 正しかった. silence_tで行きましょう
    - N2C_22
        - spk: N2C_4
        - pretrain: なし
        - 実行時間: /50epoch
        - batch_sizeのみ32にしてみる. warm_up_rateもちゃんと1/4にして.
        - 微悪化. 次はgroupsizeも元の16に戻してみて実験.
    - N2C_23
        - spk: N2C_4
        - pretrain: なし
        - 実行時間: 35min/50epoch
        - batch_size:32, group_size:16. warm_up_rateもちゃんと1/4にして.
        - マシになっている気がする. より安定している?
            - これはpaddingが減ったことに依りそう.
            - 音質も、N2C_4のものよりも安定していた気がした.
        - これをさらにloss下げたら結構よさそう.
            - そのために, warmuprateをいじってみる.
    - N2C_24
        - spk: N2C_4
        - pretrain: なし
        - 実行時間: /50epoch
        - batch_size:32, group_size:16. warm_up_rate: 2000
            - つまり, batch_size 1/4に対して1/2なので, 実質2倍遅くしている.
            - 微悪化...。今度は逆に, 実質2倍早くしてみる.
    - N2C_25
        - spk: N2C_4
        - pretrain: なし
        - 実行時間: /50epoch
        - batch_size:32, group_size:16. warm_up_rate: 500
            - つまり, batch_size 1/4に対して1/8なので, 実質2倍速くしている.
            - ほぼ効果なし.
            - じゃあmax_iterを制限しなければ...?
    - N2C_26
        - spk: N2C_4
        - pretrain: なし
        - 実行時間: /50epoch
        - batch_size:32, group_size:16. warm_up_rate: 1000, max_lr_scale: 1000
            - 上限をなくしてみた.
            - 超微悪化. 少なくとも改善はなし.
    - 結論, batch_size増で微悪化は防げず. 以下、N2C_23と同じ設定で行く.
    - N2C_27
        - spk: N2C_4
        - pretrain: なし
        - 実行時間: /50epoch
        - batch_size:32, group_size:16. warm_up_rate: 1000
        - wGMMの再実行. silence問題とwarm_up_rate勘違い問題を修正した後の初実行. sotaが予想される.
        - ほかのパラメタはよさげなセット(N2C_9).   
            - inferenceでNaN問題が生じたので、epoch150からsigma clipを利用している.
                - そのせいで, 150以降で爆発みたいなことが起きてしまっている. あまりよくないかも.
    - N2C_28
        - spk: N2C_4
        - pretrain: N2C_23(100epoch)
        - 実行時間: /50epoch
        - batch_size:32, group_size:16. warm_up_rate: 1000, reset_optim: True
        - lossはほぼ同じだが, prosody loss等は改善しているし, 自然性も向上している. 一方で, N2C_27と比べて単に200epoch回したおかげという可能性もあるので, N2C_27を再度回して確認.
    - N2C_29
        - spk: N2C_4
        - pretrain: なし
        - 実行時間: 39min/50epoch
        - batch_size:32, group_size:16. warm_up_rate: 1000
        - wGMMの再実行. 実行時, sigmaがバカでかくなってしまい, Normalがinfを出してそれ以降でinf-inf→NaNとなる問題に対処.
            - 単に, sigmaをclip(max=1.5)することにしてみた. 解決できたが, 学習初期に悪影響をもたらす可能性を否定できない.
            - なので, ちゃんとこれを導入してからもう一度200まで訓練してみて, N2C_27と大きな違いがなければ今後も採用.
        - 違いがないどころか, 若干改善していた. よい.
    - N2C_30
        - spk: N2C_4
        - pretrain: なし
        - 実行時間: 39min/50epoch
        - batch_size:32, group_size:16. warm_up_rate: 1000
        - wGMMの再実行. 実行時, sigmaがバカでかくなってしまい, Normalがinfを出してそれ以降でinf-inf→NaNとなる問題に対処.
            - 今回は, clipではなく, ELU+1を利用してみる.
        - 結果: ほぼほぼ同じだが, lossは若干少な目. 加えて、clipみたいなハードコーディングの値が必要ないのは好印象. こっちを利用.

    - 今後
        - pitchARのsentence_duration内でのみARする方式に変更
            - NARとARの中間を目指すことで高速化とloss伝播を防ぐ.
        - durationを細かくしてみる
            - それによってより細かい制御が可能になるのか検証
    - N2C_31
        - spk: N2C_4
        - pretrain: なし
        - 実行時間: 37min/50epoch
        - batch_size:32, group_size:16. warm_up_rate: 1000
        - pitchARではなく, pitchARNAR.
            - つまり, snt_durationを利用して, それ毎にpitchARを行うようにしたもの.
        - 正直微妙な違いすぎる. pitchARよりも気持ち感情がこもっているような気もする...。ただ明確に違う！という感じはしない(lossも一緒だし)
            - wGMMと組み合わせて初めて効果を発揮しそうなので, そちらを試してみる.
    - N2C_32
        - spk: N2C_4
        - pretrain: N2C_31(300epoch)
        - 実行時間: 40min/50epoch → min/50epoch
        - batch_size:32, group_size:16. warm_up_rate: 1000
        - pitchARではなく, pitchARNAR. それに加えてwGMM
            - いい気がする. あくまで気がするだけ. ちゃんと比較してから。
        - 期待していた高速化効果はそんなに単純ではなかった
            - 現状は, 新たなbatchとして通常batch_sizeごとにまとめているが, それをかなり大きくしてみた → 逆に低速に
                - 細かく分けることで, padの量が減ってデータ量減少, 速度高速化の効果の方が上回った.
                - なので, 通常batchと大規模batchの間に良さそうなものがありそうだが、見つけるのは大変そう. なので以前同様batch_sizeとする.
    - N2C_33
        - spk: N2C_4
        - pretrain: N2C_23(300epoch)
        - 実行時間: min/50epoch
        - batch_size:32, group_size:16. warm_up_rate: 1000
        - pitchAR. それに加えてwGMM. すでにこれはN2C_28でやったことだけど, N2C_32と比較がしたいので, 300+200epoch回すということをしたい.
        - 比較の結果, 普通に全部ARする方が良さそうな音質。ここまで見たようにどっちも悪いところがあるが、こちらの方が軽傷という感じ.
            - やはり, ARを途中で切ってしまうと, prosody embの助けがあるにも関わらず、直前とテンションがガラッと変わってしまったりしていて微妙。
        - 結論: 素直に全部ARでヨシ.
    
    - min_silence_len=100を作る最中に, assertになる事態が.
    - 原因としては, reduction_factorのせいで細かいところがつぶれ, きちんと対応が取れなくなってしまったという.
        - これのせいで, min_silence_len=500とかでも普通にミスが起こっている.
        - なので, 実行時間がかなり遅くなるのは覚悟のうえで、一度reduction_factor=1でやってみるべきかもしれない.
    - N2C_34
        - spk: N2C_5
        - pretrain: なし
        - 実行時間: 150min/50epoch
        - batch_size:32, group_size:16, warm_up_rate: 1000, min_silence_len: 500, reduction_factor: 1
        - wGMM. N2C_30と比較して, reduction_factorはどちらがよいのか検討.
            - 精度に関しては上がらないとおかしそう。ただ、実行時間が純粋に3倍になりそうな予感...。
            - AR部分がボトルネックになってくるので、ここでpitchARNARの出番かもしれない.
        - 当然メモリに乗り切るはずもなく, Batch_size=12まで下げた.
            - それとreductionのおかげで1epoch 3minまで遅くなりました. → 150min/50epoch ← N2C_30の約3.75倍...。
        - 終了. pitchが悲惨
            - 単純に問題を簡単にするためにreduction factorは必要.
    - reduction_factorは可能であれば3のままにしたい...!
        - preprocessで頑張って辻褄の合うsentence_durationを作れ！！！
    - N2C_35
        - spk: N2C_6
        - pretrain: なし
        - 実行時間: 39min/50epoch
        - batch_size:32, group_size:16, warm_up_rate: 1000, min_silence_len: 500, reduction_factor: 3
        - wGMMの標準的な設定. **durationの計算方法を変えた**
        - かなりよくなっているはずなので, N2C_30と比較してどちらがよかったか一応比較.
        - 大悪化!!!!
            - energyが悲惨なことになってしまう.
            - energyはいじっていないのに....
            - get_durationを見返すと, 80melで計算している
                - 20でないと正しくdtw出来ない可能性.
    - N2C_36
        - spk: N2C_7
        - pretrain: なし
        - 実行時間: min/50epoch
        - batch_size:32, group_size:16, warm_up_rate: 1000, min_silence_len: 500, reduction_factor: 3
        - get_durationをちゃんと20melで計算しようの会
        - 結果: 変わらず.
            - melはdtwに影響を与えない!!!!
    - 結論: dtwではいいdurationを作れない(元データがゴミなので)
        - oldの方でやると, ノイズは無視してくれる(reductionした後にアライメントをとるので)一方で、
        やはり細かいところを無視してsnt_duration作成で0が生まれたりしてしまうのは致命的.
        - その一方で, newの方は, まずやはり勝手にroundの補正をすると辻褄が合わなくなって, 特にenergyが困惑してしまっていた.
        また, 細かく見すぎて逆にノイズを重視してしまい、変なことになったりもしていた.
        - なので、要するにデータがきれいでないとdtwでアライメント作成は無理です.
        - 研究であれば、「じゃあきれいなデータを用意しろ」で済むけれど、これは僕の趣味用でもあり、プロダクト化も見据えている
            - なので, 可能ならノイズが多少あってもちゃんと動くようなものがいい.
        - そこで、原点回帰だけれど, Tacotron2VCを訓練して, そこからアライメントをとる方向にします.
    - N2C_37
        - spk: N2C_8
        - pretrain: なし
        - 実行時間: 40min/50epoch
        - batch_size:32, group_size:16, warm_up_rate: 1000, min_silence_len: 500, reduction_factor: 3
        - get_durationをTacotron2VCによるものとして計算してみる.
        - 結果:
            - 発話が割と改善されている(まだ少し漏れはある).
            - prosodyも同等か改善という感じ(モノによっては大分マシになっている).
            - 総合的には、改善！(lossは高いが...。)
    - N2C_38
        - spk: N2C_9
        - pretrain: なし
        - 実行時間: 40min/50epoch
        - batch_size:32, group_size:16, warm_up_rate: 1000, min_silence_len: 50, reduction_factor: 3
        - get_durationをTacotron2VCによるものとして計算してみる.
        - 結果:
            - 発話の崩れは完璧になくなった.
            - その一方で, prosodyは問題点二つ
                - durationがおかしい
                    - 細かく区切ってそこ毎に制御しているので仕方ないか?
                - pitchが全体的に低め
                    - これは謎. なんで?
            - 総合的には, 悪化と言えそう.
                - durationを学習ありにしたりしたらマシになるか?
                - pitchはよくわからんけど...。
                - teacher forcingでも, 細かすぎるのが目立っていたので.
    - N2C_39
        - spk: N2C_8
        - pretrain: なし
        - 実行時間: 31min/50epoch
        - batch_size:32, group_size:16, warm_up_rate: 1000, min_silence_len: 500, reduction_factor: 3, pitch_AR: False
        - N2C_37にて, pitchがcontinuousになっていないのが気になったので, pitch_ARをFalseにしたらどうなるのかやってみる.
    - N2C_40
        - spk: N2C_10
        - pretrain: なし
        - 実行時間: 30min/50epoch
        - batch_size:32, group_size:16, warm_up_rate: 1000, min_silence_len: 200, reduction_factor: 3, pitch_AR: False
            - ある程度の細かさで試したらどうなるのか.
        - 結果:
            - loss: prosodyがヤバい. 暴れまくっている.
            - 音質: かなり改善！！！めちゃくちゃexpressive
                - 正直いいところしかなくない気がする.
                - もちろんこれでも完ぺきではないが, それを言い出したら他はもっとミスがあるので.
                - durationも改善されていた. N2C_41はいらないかも.
            - やはり, 適度にwGMMをフル活用するのが一番よい結果になる.
        - 結論: 今後はmin_silence_len=200で行く.
    - N2C_41
        - spk: N2C_8
        - pretrain: なし
        - 実行時間: min/50epoch
        - batch_size:32, group_size:16, warm_up_rate: 1000, min_silence_len: 500, reduction_factor: 3, pitch_AR: False
        - durationとenergyもstop grad flow=Trueにしてみる.
        - 結果:
            - loss: 微悪化? 当然ながらより学習は困難になるので.
            - 音質: 改善!
                - prosodyがより自然になっている(不自然にふらふらしていないという意味)
                - 何よりdurationが自然!
            - だだ, それに伴って(?) 少し感情を失ってしまっている印象がある.
        - 結論: 手放しには褒められない. 正直どちらでもいいかも.
        - 追記: duration問題はN2C_40で改善したので, 今後はN2C_40でいく. grad flowとかはそのまま.
    - N2C_42
        - spk: N2C_8
        - pretrain: なし
        - 実行時間: min/50epoch
        - batch_size:32, group_size:16, warm_up_rate: 1000, min_silence_len: 500, reduction_factor: 3, pitch_AR: False
        - すべてのgrad flowを逆にFalseにしてみる. 念のための実験.
        - 比較対象はN2C_39
        - だめ. 過学習の鬼.
        - 結論: 
            - 元パラメタは偉大. 今後もpitchのgradflowは止めよう.
    - N2C_43
        - spk: N2C_9
        - pretrain: なし
        - 実行時間: min/50epoch
        - batch_size:32, group_size:16, warm_up_rate: 1000, min_silence_len: 50, reduction_factor: 3, pitch_AR: False
        - min_silence_len=200+pitchAR=Falseでうまくいったので、これも一応確かめておく.
        - 結果:
            - N2C_40と比べて, どっこいどっこい. この二つは得意不得意がありそう.
            - まぁどちらでもよいといえばいいが, こちらでうまくいかせたい気持ちがあるので, 今後は200と50で比較していく.
    - ここまでで, できる実験はあらかたやって、結果もある程度出せたと思われる.

    - ここまでの大まかなまとめ
        - pitchAR < wGMM
            - ↑こちら二つは同居させず, wGMM onlyのがよい
        - dtw < Tacotron2
            - ↑これによってlen=50msのsnt_durationも作成可能に.

    - あとは, pretrainのいいやり方を試してみて, sotaを作り上げてみる.
    - 具体的には, [Voice Transformer Network: Sequence-to-Sequence Voice Conversion Using Transformer with Text-to-Speech Pretraining](https://aria3366.hatenablog.com/entry/2020/10/20/172807)

    - JSUT_NICT_LINE_1
        - spk: JSUT_NICT_LINE
        - pretrain用
        - 上述のよさげな初期化方法に従って, 今持ちうるすべてのデータを使ってガッツリ初期化してみた. decoderはfixされている.
        - 実行中に生じた問題
            - CUDA memory Error
                - なぜか60epoch回って急にこれが出だす.
                - 単純に長い発話を削除することで対応
            - GRU, pad paddedにてRuntime Error
                - なぜかmelとpitchのshapeがあっていないせいで発生.
                - durationの中身が固定されてしまっている以上, pitchの方を合わせに行くべき.
                - mel < pitch: この時は, reductionの時に削ってくれるので問題なし.
                - mel > pitch: これがエラー起こるので, reprocessにてs_mel_max_lenでpadすることで対処.
    - N2C_44
        - spk: N2C_9
        - pretrain: JSUT_NICT_LINE_1
        - 実行時間: min/50epoch
        - batch_size:32, group_size:16, warm_up_rate: 1000, min_silence_len: 50, reduction_factor: 3, pitch_AR: False
        - 結果:
            - 最高. ほぼ完成では? 音質がいいのは500epochも回したからそれはそうなんだけど、発話も壊れていないし、それでいて感情も残されている！！
            - 一つ気になったのは, duration. なんかうまく学習できていない...。
            - 場合によっては, durationのgradient_flowを切った方がいいかもしれない.
            - それよりも, min_silence_lenが細かいというのが原因にありそうなので、200で試してみる↓.
    - JSUT_NICT_LINE_2
        - spk: JSUT_NICT_LINE_2
        - pretrain用
        - min_silence_len: 200で試してみるお話.
    - N2C_45
        - spk: N2C_10
        - pretrain: JSUT_NICT_LINE_2
        - 実行時間: min/50epoch
        - batch_size:32, group_size:16, warm_up_rate: 1000, min_silence_len: 200, reduction_factor: 3, pitch_AR: False
        - 結果:

## 主要な実験
- N2C_4: 初pitchAR化.
- N2C_23: batch_size: 32におけるpitchARの訓練. pre-train用.
- N2C_30: wGMMの正しい初訓練(ELUで). 完全にN2C_23の上位互換. 成功.
- N2C_33: 現状のsota. pitchAR+wGMM+pretrain
- N2C_40: ↑さらなるsota. wGMM+min_silence_len=200

## 知見
- silence_thresh_tは-80より-100のがよい(N2C_20)
    - 削りすぎるよりはのこしておいた方がよいのかもしれない.
    - 更に削るとどうなるかは気になる.
    - **datasetを作り直したら、今までのbestで比較するべき**

- groupsizeは小さい方がよい??(N2C_18, N2C_19)
    - これは非直感的.
    - valもtrainも若干改善といった具合.
        - 特に速度にも影響しないので, 小さくしておくべきかも.
    - N2C_22, N2C_23にて, 大きい方がより安定した！という結果に.
        - Batch_sizeが大きいときは, よりgroup_sizeが大きい方が
        - padding問題もあって安定しそう.
        - 常に, batch_size/2 = group_size位がちょうどいいのかも.

- batch_sizeは小さい方がよい??(N2C_21, N2C_22)
    - ただし、warm_up_rateは単純にbatch_sizeの比率でスピードを変えているだけ.
    - batch_sizeが小さい方がよいのは、データセットが小さい場合は確かに一般的に言えることではあるので、正しそう.
    - 一方で, batch_sizeを小さいまま訓練するのは時間的に厳しいため, warm_up_rateの方などで調整をして何とかこの差をなくしてあげるべき.
        - warm_up_rateで下げるのは厳しかった(N2C_24~N2C_26)
        - 0.01の差なので, 許容する.
            - 本当に精度が欲しいときは, 時間をかけてbatch_size=8でやるというやり方でいく.

- wGMMの方が, pitchARよりよい(N2C_23, N2C_29)
    - 今までは, wGMMの時にwarm up rateをミスったりデータセットが違ったりで正しく比較できていなかった.
    - ここにきて初めてちゃんと比較.
    - 結果
        - loss:
            - dev: 同じ
            - train: wGMMの方が高い
            - つまり, 過学習度合いが弱まり、実質の改善といえる.
        - 音質:
            - 改善. pitchARは基本的に前半からのミスが積み重なって最後とか超高音になったりしている.
                - 発話も壊れ気味.
            - 一方, wGMMは同じ傾向もものによっては見られるものの, 一部発話では発話がより明瞭になったりして安定.
    - 結論: VCにおいてwGMMは効く.
    - 問題点
        - pitchのミスが増幅される
            - pitchをresetする機構を作ってみる.

- sigma爆発問題の対処方法は, 「ELU+1」がよい
    - MDNの元論文では、expが使われていたが、ここまでさんざん見たように, expを用いると爆発してinf-inf=NaNが発生しうる.
    - 防ぐ方法としては,
        - expをclipしてしまう
            - 途中からclip: N2C_27
                - 割とlossが暴れているので、よくなさそう
            - 最初からclip: N2C_29
                - 成功. 普通に安定してくれた.
        - expではなく, ELU+1を使う
            - N2C_30
                - 結果はほぼ同じ！詳細はN2C_30のところを参照.
        - 他にも, 単なるReLUでもいいし, softplusでも良さそう.
    - 色々あるが、今回は「ELU+1」を採用する。

- pretrainは「ある」方がよい(たぶん)
    - N2C_28: pretrainあり
    - N2C_29: pretrainなし
    - 比較が平等になるように, 同じlrの時で比較
    - 結果
        - 音声評価: 同じくらい→どちらも外しているところが違くて何とも言えない
        - 画像評価: pretrainの方が若干よい?
            - 発言の最初にちゃんと高いのをpretrainは予測できている.
            - pretrainなしの方は必ず低いところから始まる...。
        - loss評価: pretrainの方がよい
            - pitchなどの基本的なlossは変わらない.
            - prosody lossは, 予想通りpretrainしていた方が低くまで下がる.
    - 結論: 今後はpretrainしよう!

- pitchARNARは, 「ない」方がよい
    - N2C_32: pitchARNAR
    - N2C_33: pitchAR
    - pitchARくんもかなり大こけしているが、pitchARNARはやはり途中で切ってしまうことでテンションがガラッと変わったりしてしまい、不自然.
    - 実行時間も結局高速化！どころか逆に遅くなってしまっているし微妙すぎた.
    - 結論: 今後はpitchARでいく.

- min_silence_lenは, 「細か過ぎず、適度な」方がよい
    - N2C_37: min_silence_len=500
    - N2C_38: min_silence_len=50
    - 細かいことで, 発話は保存されやすくなった.
    - その一方で, durationがバラバラだったり, pitchも.
        - AR化しているのに...という感じだが, 実際はテンションバラバラという感じ.
        - teacher forcingにすら細かいことでなんか変な感じになっている影響があった.
        - 恐らく, 細かくなればなるほどコンテントリークが激しくなるのだろう.
    - 諸々を考慮すると, 長い方が良さそう.
    - 長い方の発話崩れは, pretrainによって改善するので問題なし.
    - 結論: 今後は長い方で行く.
    - 追記: 適度な長さで見たら, N2C_40, 滅茶苦茶よかった！！！
    - 使う使わないメリット両取りって感じ. 今後はこれで行く.

- wGMMの下では, PitchARは「いらない」。
    - N2C_37: Tacotron2のdurationで, pitchAR=True
    - N2C_39: pitchARのみFalse
    - 明らかな改善でびっくりしている.
    - 直感的にも, 二重にARは明らかに不要だし.
    - pitchがARになっていない分, lossの伝播がすくない. そのため、情緒不安定みたいなことにあまりなっていないという感じ.
        - 一方で, AR出なくなったためにpitchがゆらゆらしたりするマイナス面も.
    - pitchARで訓練したものをpretrainとするととてもよさそうな予感
    - 結論: wGMMの時は, pitchAR=Falseで.

- get_duration時に使うmelの次元は, 20でも80でも変わらない
    - N2C_36で検証.

## 実験以外の知見
- 高速化, メモリ省エネ化について
    - group_sizeは影響なさそう. やはりbatch_sizeが大きい.
    - pytorchは変数名が同じだとしても新しく割り当てようとするから、頑張って統一してもメモリは増える
    - メモリfreeは対して影響がない. もしかしたら自動でfreeしてくれているのかも.
        - むしろ, [cacheがなくなるせいで次にメモリに乗せる時間が遅くなる](https://kamakuraviel.hatenablog.com/entry/2020/08/23/193446#%E5%9F%BA%E6%9C%AC%E7%9A%84%E3%81%AA%E6%8C%99%E5%8B%95CPU)みたい.
    - 結論: ちょっとやそっとじゃメモリ節約は出来ない. 諦めろ.

### JSUT_NICT_LINEにて削除した長い発話

```
 'Teacher_Teacher_SD04-Dialogue-51-Teacher-Turn-02'
 'Teacher_Teacher_SD12-Dialogue-30-Teacher-Turn-02'
 'FStudent_FStudent_LD13-Dialogue-08-FStudent-Turn-05'
 'Teacher_Teacher_SD10-Dialogue-29-Teacher-Turn-02'
 'Teacher_Teacher_SD10-Dialogue-40-Teacher-Turn-02'
 'Teacher_Teacher_SD09-Dialogue-23-Teacher-Turn-02'
 'Teacher_Teacher_SD09-Dialogue-07-Teacher-Turn-02'
 'Teacher_Teacher_SD09-Dialogue-25-Teacher-Turn-02'
 'Teacher_Teacher_SD03-Dialogue-18-Teacher-Turn-02'
 'Teacher_Teacher_SD04-Dialogue-40-Teacher-Turn-02'
 'Teacher_Teacher_SD12-Dialogue-01-Teacher-Turn-02'
 'FStudent_FStudent_SD10-Dialogue-06-FStudent-Turn-01'
 'Teacher_Teacher_SD12-Dialogue-08-Teacher-Turn-02'
 'Teacher_Teacher_SD04-Dialogue-34-Teacher-Turn-02'
 'Teacher_Teacher_SD06-Dialogue-33-Teacher-Turn-02'
 'Teacher_Teacher_SD11-Dialogue-31-Teacher-Turn-02'
 'Teacher_Teacher_SD06-Dialogue-29-Teacher-Turn-02'
 'FStudent_FStudent_SD09-Dialogue-07-FStudent-Turn-02'
 'Teacher_Teacher_SD03-Dialogue-55-Teacher-Turn-02'
 'Teacher_Teacher_SD02-Dialogue-32-Teacher-Turn-02'
 'Teacher_Teacher_SD04-Dialogue-53-Teacher-Turn-02'
```