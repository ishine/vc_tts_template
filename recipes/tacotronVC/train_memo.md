# train_memo

- spk
    - N2C
        - N2C初回.
    
    - jsut_jsss_jvs
        - 上に書いてあるコーパスすべてのVC. multi.
        - pretrain用.
    - jsut_jsss
        - one2one
        - 一応pretrain用

- tag
    - N2C_1
        - spk: N2C
        - pretrain: None
    - jsut_jsss_jvs_1
        - spk: jsut_jsss_jvs
        - pretrain用.
        - あほみたいな量のデータだったけどダメ
            - ↑マルチスピーカーは無理なのかも?
    - jsut_jsss_1
        - spk: jsut_jsss
        - pretrain用
    - N2C_2
        - spk: N2C
        - pretrain: jsut_jsss_1
            - かなりマシ. pretrainは必須ですね.
    - jsut_jsss_2
        - spk: jsut_jsss
        - pretrain用
        - lossとして、guided attention lossを追加したので.
        - とても良いので, 200epoch回しておく.
    - N2C_3
        - spk: N2C
        - pretrain: jsut_jsss_2
            - すごい.
            - これでいく. とりあえずもっと回しておく.
    - N2C_4
        - spk: N2C
        - pretrain: jsut_jsss_2(after 200epoch)