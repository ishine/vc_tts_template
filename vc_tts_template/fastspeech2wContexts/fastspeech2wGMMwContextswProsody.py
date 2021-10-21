from typing import Dict, Optional

import torch.nn as nn

from vc_tts_template.fastspeech2wGMM.fastspeech2wGMM import FastSpeech2wGMM
from vc_tts_template.fastspeech2wContexts.context_encoder import ConversationalProsodyContextEncoder
from vc_tts_template.fastspeech2wContexts.prosody_model import ProsodyPredictorwAttention


class fastspeech2wGMMwContextswProsody(FastSpeech2wGMM):
    """ fastspeech2wGMMwContextswProsody """

    def __init__(
        self,
        max_seq_len: int,
        num_vocab: int,  # pad=0
        # encoder
        encoder_hidden_dim: int,
        encoder_num_layer: int,
        encoder_num_head: int,
        conv_filter_size: int,
        conv_kernel_size_1: int,
        conv_kernel_size_2: int,
        encoder_dropout: float,
        # context encoder
        context_encoder_hidden_dim: int,
        context_num_layer: int,
        context_encoder_dropout: float,
        text_emb_dim: int,
        g_prosody_emb_size: int,
        # prosody extractor
        prosody_emb_dim: int,
        extra_conv_kernel_size: int,
        extra_conv_n_layers: int,
        extra_gru_n_layers: int,
        extra_global_gru_n_layers: int,
        # prosody predictor
        gru_hidden_dim: int,
        gru_n_layers: int,
        pp_conv_out_channels: int,
        pp_conv_kernel_size: int,
        pp_conv_n_layers: int,
        pp_conv_dropout: float,
        pp_zoneout: float,
        num_gaussians: int,
        global_gru_n_layers: int,
        global_d_gru: int,
        global_num_gaussians: int,
        prosody_emb_size: int,
        attention_hidden_dim: int,
        attention_conv_channels: int,
        attention_conv_kernel_size: int,
        # variance predictor
        variance_predictor_filter_size: int,
        variance_predictor_kernel_size: int,
        variance_predictor_dropout: int,
        pitch_feature_level: int,  # 0 is frame 1 is phoneme
        energy_feature_level: int,  # 0 is frame 1 is phoneme
        pitch_quantization: str,
        energy_quantization: str,
        n_bins: int,
        # decoder
        decoder_hidden_dim: int,
        decoder_num_layer: int,
        decoder_num_head: int,
        decoder_dropout: float,
        n_mel_channel: int,
        # other
        encoder_fix: bool,
        global_prosody: bool,
        stats: Dict,
        speakers: Dict,
        emotions: Optional[Dict] = None,
        accent_info: int = 0,
    ):
        super().__init__(
            max_seq_len,
            num_vocab,
            encoder_hidden_dim,
            encoder_num_layer,
            encoder_num_head,
            conv_filter_size,
            conv_kernel_size_1,
            conv_kernel_size_2,
            encoder_dropout,
            prosody_emb_dim,
            extra_conv_kernel_size,
            extra_conv_n_layers,
            extra_gru_n_layers,
            extra_global_gru_n_layers,
            gru_hidden_dim,
            gru_n_layers,
            pp_conv_out_channels,
            pp_conv_kernel_size,
            pp_conv_n_layers,
            pp_conv_dropout,
            pp_zoneout,
            num_gaussians,
            global_gru_n_layers,
            global_d_gru,
            global_num_gaussians,
            variance_predictor_filter_size,
            variance_predictor_kernel_size,
            variance_predictor_dropout,
            pitch_feature_level,
            energy_feature_level,
            pitch_quantization,
            energy_quantization,
            n_bins,
            decoder_hidden_dim,
            decoder_num_layer,
            decoder_num_head,
            decoder_dropout,
            n_mel_channel,
            encoder_fix,
            global_prosody,
            stats,
            speakers,
            emotions,
            accent_info,
        )
        # override to add padding_idx
        n_speaker = len(speakers)
        self.speaker_emb = nn.Embedding(
            n_speaker,
            encoder_hidden_dim,
            padding_idx=0,
        )
        self.emotion_emb = None
        if emotions is not None:
            n_emotion = len(emotions)
            self.emotion_emb = nn.Embedding(
                n_emotion,
                encoder_hidden_dim,
                padding_idx=0,
            )

        self.context_encoder = ConversationalProsodyContextEncoder(
            d_encoder_hidden=encoder_hidden_dim,
            d_context_hidden=context_encoder_hidden_dim,
            context_layer_num=context_num_layer,
            context_dropout=context_encoder_dropout,
            text_emb_size=text_emb_dim,
            g_prosody_emb_size=g_prosody_emb_size,
            speaker_embedding=self.speaker_emb,
            emotion_embedding=self.emotion_emb,
        )
        self.prosody_predictor = ProsodyPredictorwAttention(
            encoder_hidden_dim,
            gru_hidden_dim,
            prosody_emb_dim,
            pp_conv_out_channels,
            conv_kernel_size=pp_conv_kernel_size,
            conv_n_layers=pp_conv_n_layers,
            conv_dropout=pp_conv_dropout,
            gru_layers=gru_n_layers,
            zoneout=pp_zoneout,
            num_gaussians=num_gaussians,
            global_prosody=global_prosody,
            global_gru_layers=global_gru_n_layers,
            global_d_gru=global_d_gru,
            global_num_gaussians=global_num_gaussians,
            h_prosody_emb_size=prosody_emb_size,
            attention_hidden_dim=attention_hidden_dim,
            attention_conv_channels=attention_conv_channels,
            attention_conv_kernel_size=attention_conv_kernel_size,
        )

    def contexts_forward(
        self,
        output,
        max_src_len,
        c_txt_embs,
        speakers,
        emotions,
        h_txt_embs,
        h_txt_emb_lens,
        h_speakers,
        h_emotions,
        h_g_prosody_embs
    ):
        context_enc = self.context_encoder(
            c_txt_embs,
            speakers,
            emotions,
            h_txt_embs,
            h_speakers,
            h_emotions,
            h_txt_emb_lens,
            h_g_prosody_embs,
        )
        output = output + context_enc.unsqueeze(1).expand(
            -1, max_src_len, -1
        )
        return output

    def prosody_forward(
        self,
        output,
        src_lens,
        src_masks,
        mels,
        p_targets,
        d_targets,
        h_prosody_emb,
    ):
        is_inference = True if p_targets is None else False

        prosody_target, g_prosody_target = self.prosody_extractor(mels, d_targets, src_lens)
        prosody_prediction, pi_outs, sigma_outs, mu_outs, g_pi, g_sigma, g_mu = self.prosody_predictor(
            output, h_prosody_emb,
            target_prosody=prosody_target, target_global_prosody=g_prosody_target,
            src_lens=src_lens, src_mask=src_masks, is_inference=is_inference
        )
        if is_inference is True:
            output = output + self.prosody_linear(prosody_prediction)
        else:
            output = output + self.prosody_linear(prosody_target)

        return (
            output,
            [prosody_target,
                pi_outs,
                sigma_outs,
                mu_outs,
                g_prosody_target,
                g_pi,
                g_sigma,
                g_mu]
        )

    def forward(
        self,
        ids,
        speakers,
        emotions,
        texts,
        src_lens,
        max_src_len,
        c_txt_embs,
        h_txt_embs,
        h_txt_emb_lens,
        h_speakers,
        h_emotions,
        h_prosody_emb,
        h_g_prosody_embs,
        mels=None,
        mel_lens=None,
        max_mel_len=None,
        p_targets=None,
        e_targets=None,
        d_targets=None,
        p_control=1.0,
        e_control=1.0,
        d_control=1.0,
    ):
        src_lens, max_src_len, src_masks, mel_lens, max_mel_len, mel_masks = self.init_forward(
            src_lens, max_src_len, mel_lens, max_mel_len
        )
        output = self.encoder_forward(
            texts, src_masks, max_src_len, speakers, emotions
        )
        output = self.contexts_forward(
            output, max_src_len, c_txt_embs, speakers, emotions,
            h_txt_embs, h_txt_emb_lens, h_speakers, h_emotions,
            h_g_prosody_embs,
        )

        output, prosody_features = self.prosody_forward(
            output, src_lens, src_masks,
            mels, p_targets, d_targets, h_prosody_emb,
        )
        (
            output,
            p_predictions,
            e_predictions,
            log_d_predictions,
            d_rounded,
            mel_lens,
            mel_masks,
        ) = self.variance_adaptor(
            output,
            src_masks,
            mel_masks,
            max_mel_len,
            p_targets,
            e_targets,
            d_targets,
            p_control,
            e_control,
            d_control,
        )
        output, postnet_output, mel_masks = self.decoder_forward(
            output, mel_masks
        )

        return (
            output,
            postnet_output,
            p_predictions,
            e_predictions,
            log_d_predictions,
            d_rounded,
            src_masks,
            mel_masks,
            src_lens,
            mel_lens,
            prosody_features,
        )