import numpy as np
import torch
from pathlib import Path


@torch.no_grad()
def synthesis(device, lab_file, context_embedding, 
              speaker_dict, emotion_dict, acoustic_model,
              acoustic_out_scaler, vocoder_model):
    ids = [Path(lab_file).name.replace("-feats.npy", "")]

    (
        current_txt_emb, history_txt_embs, hist_emb_len, history_speakers, history_emotions
    ) = context_embedding

    if speaker_dict is None:
        raise ValueError("You Need speaker_dict")
    else:
        speakers = np.array([speaker_dict[fname.split("_")[0]] for fname in ids])
        h_speakers = np.array([speaker_dict[speaker] for speaker in history_speakers])
    if emotion_dict is None:
        emotions = np.array([0])
        h_emotions = np.array([0 for _ in range(len(h_speakers))])
    else:
        emotions = np.array([emotion_dict[fname.split("_")[-1]] for fname in ids])
        h_emotions = np.array([emotion_dict[emotion] for emotion in history_emotions])

    in_feats = np.load(lab_file)
    src_lens = [in_feats.shape[0]]
    max_src_len = max(src_lens)

    speakers = torch.tensor(speakers, dtype=torch.long).to(device)
    emotions = torch.tensor(emotions, dtype=torch.long).to(device)
    in_feats = torch.tensor(in_feats, dtype=torch.long).unsqueeze(0).to(device)
    src_lens = torch.tensor(src_lens, dtype=torch.long).to(device)
    current_txt_emb = torch.tensor(current_txt_emb).unsqueeze(0).to(device)
    history_txt_embs = torch.tensor(history_txt_embs).unsqueeze(0).to(device)
    hist_emb_len = torch.tensor(hist_emb_len, dtype=torch.long).unsqueeze(0).to(device)
    h_speakers = torch.tensor(h_speakers, dtype=torch.long).unsqueeze(0).to(device)
    h_emotions = torch.tensor(h_emotions, dtype=torch.long).unsqueeze(0).to(device)

    output = acoustic_model(
        ids=ids,
        speakers=speakers,
        emotions=emotions,
        texts=in_feats,
        src_lens=src_lens,
        max_src_len=max_src_len,
        c_txt_embs=current_txt_emb,
        h_txt_embs=history_txt_embs,
        h_txt_emb_lens=hist_emb_len,
        h_speakers=h_speakers,
        h_emotions=h_emotions,
    )

    mel_post = output[1]
    mels = [acoustic_out_scaler.inverse_transform(mel.cpu().data.numpy()) for mel in mel_post]  # type: ignore
    mels = torch.Tensor(np.array(mels)).to(device)
    wavs = vocoder_model(mels.transpose(1, 2)).squeeze(1).cpu().data.numpy()

    return wavs[0]
