# モデルコード一般化プロジェクト(作成中)
- 目的: 今後, いろんなモデルを実装していくにあたり, 毎回dataloaderとかtrainとか書くのあほくさい.
- なので, 使いまわし可能なコードを作ろう!!!


## 謝辞
こちらのコードは、[ttslearn](https://github.com/r9y9/ttslearn)をベースにして作られています。hifiganに関しては、[こちら](https://github.com/jik876/hifi-gan)、fastspeech2に関しては、[こちら](https://github.com/ming024/FastSpeech2)がベースです。
## todo
- check_grad: 10回くらい？連続でNaNを出すようなパラメタがある場合はraiseしてもいいかもしれない. あまりにひどい場合実装してみる.
- wGMMのGRUにdropoutを導入検討
- wContextsのsynthesis, tuning, gen, tts

## memo
- [勾配計算を可視化したかったらtorchvizが楽かも](https://github.com/szagoruyko/pytorchviz)
    - ↑これは結局, renderが重すぎてむり
    - train_utilsにplot_grad関数を用意した.

- detach()について
    - detachだけだと, メモリが共有されてしまうため、何か変更を与える(例えば+とか)と勾配計算の時エラーになる。防ぐ方法としては、
        - clone()
        - torch関数で演算
    - の2択. まぁ完全に切って使いたかったらclone detachでよさそう(順番は逆でok)

    - **というよりも, 「+=」を使うな！！！！**
        - 単純な足し算はしていないっぽい。fastspeech2の実装もわざわざx = x + ... とかやっていたのはこういう理由.
        - 特殊な利用方法以外は特に問題起きないみたい. でも念のため.
        - 実験結果
            - y = y + 1 だと, yのidは変わる.
            - y += 1 だと**変わらない**
        - つまり, 
            - y = x.detach()  # detachされ, idは変わるがメモリは共有してしまっている.
            - y += tensor.Tensor([3]) # xのメモリに上書きされてしまう. そのため事故が起こる
            - y = y + tensor.Tensor([3])  # この時, yは新しく作られていて, もはや別物. xのメモリに影響も与えない

- optuna
    - [基本の流れ](https://qiita.com/studio_haneya/items/2dc3ba9d7cafa36ddffa#%E5%9F%BA%E6%9C%AC%E3%81%AE%E4%BD%BF%E3%81%84%E6%96%B9)
    - [発展的な流れ](https://colab.research.google.com/github/pfnet-research/optuna-hands-on/blob/master/ja/02_Optuna_Advanced_Tutorial_ja.ipynb#scrollTo=bf0EFoaM6Q_Y)
    - [suggest関数たち](https://optuna.readthedocs.io/en/stable/reference/generated/optuna.trial.Trial.html#optuna.trial.Trial.suggest_categorical)
    - [dashboard](https://cyberagent.ai/optuna-dashboard-development)
        - `optuna-dashboard sqlite:///optuna_study.db`

- librosaできない問題、解決
    - 原因: pyenvが生き残って悪さをしていた...
    - [pyenv uninstall方法](https://www.owlog.org/update-python-environment/)
    - 関係ないけど、良さげな見つけたサイト
    - [brew](https://zenn.dev/ryuu/articles/wsl2-homebrew)

- pyauidoできない問題
    - [解決策](https://qiita.com/musaprg/items/34c4c1e0e9eb8e8cc5a1)
    - [その他入れておいたほうがよさそうなもの](https://linuxtect.com/the-error-command-gcc-failed-with-exit-status-1-error-and-solution/)

- NaN出続ける問題
    - 候補: log, /, sqrt
    - Normalの中でlogをとってしまっていることに注意
        - なので, scaleは1e-8足して渡すべき
            - torch.exp()は, -100程度で簡単に0になるので注意.
        
    - 20211004: 本格検討
        - とりあえず、勾配監視としては、infになってしまった部分を素直に取り出すのが一番. 以下に実装例を残しておく。
        - これ以外の方法は厳しそうであった。plot_gradや、それを改造して時系列ごとにgrad変化をplotするなどをしてみようとしたが、数が多すぎて無理だったり。
        - とりあえずこれを使って一度途中でNaNになりprunedされる現象を観測しよう！

        - 結論, float32で問題ないなら問題ない. ただ, あまりにもNaNが続くのは単純に学習うまくいってなさそうだし、切ってもいいかも.

実装例
```
    tmp_params = {}
    # Update
    if train:
        scaler.scale(loss).backward()
        for n, p in model.named_parameters():
            grad_v = p.grad.abs().mean().cpu().numpy()
            if grad_v == np.inf:
                tmp_params[n] = grad_v
        free_tensors_memory([loss])
        scaler.unscale_(optimizer)
        grad_norm = torch.nn.utils.clip_grad_norm_(model.parameters(), 1.0)
        if not torch.isfinite(grad_norm):
            logger.info("grad norm is NaN. Skip updating")
            for n, p in tmp_params.items():
                logger.info(f"{n}: {p}")
```


## run.shの流れ

- stage -1
    - コーパスのダウンロード.
- stage 0
    - dataをtrain, val, evalに分割している.
- stage 1
    - duration modelに対する特徴量作成.
- stage 2
    - acoustic modelに対する特徴量作成.
- stage 3
    - 正規化
- stage 4
    - durationの訓練
- stage 5
    - acousticの訓練
- stage 6
    - synth

## 気になってるところ
- configの基準
    - 2重に書いている変数とかあるけど...
    - ほかのモデルも見て考える.

## 部品に関する感想メモ
### dnnのみ
- recipes: 実行系. confとか出力とかtrainとかも.
    - common: 共通
        - yaml_parser.sh
        - parse_options.sh
            - この2つはstage -1から使用. run.shの基本.
        - qst1.hed @ stage 1
            - 言語特徴に投げるquestion.
            - 使い回し可能だが, そもそも言語特徴量使わなさそう(
        - fit_scaler.py @ stage 3
            - normalizeして, standard scalerを保存するコード.
            - 特徴量の保存ファイル名だけハードコードされているが, それ以外は使いまわせそう.
        - preprocess_normalize.py @ stage 3
            - scalerを渡して, 実際にファイルたちを正規化して保存するコード.
            - これもファイル名だけ決まっているが, 使いまわせそう.
    - dnntts
        - train_dnntts.py @ stage 4
            - train_step: これは完全に専用. lossも中で作っちゃってるし.
            - train_loop: dataloader周りも専用コード.
        - run.sh
            - 実験を再現するファイル. ↓のconfigを利用.
        - config.yaml
            - 実験全般のconfig. runに関して.
            - 一部, train_dnnttsとかぶる内容はあり.
            - その際はrun.sh内で上書きしている.
            - どういう基準でconfig書いているのかいまいち読めない...。
        - preprocess_duration.py
            - 単なる前処理. 使いまわしは困難 @ stage 1
        - preprocess_acoustic.py
            - 同様 @ stage 2
        - synthesis.py @ stage 6
            - これも思いっきりまさにdnntts用. 使えるところはなさそう.
        - data @ stage 0
            - utt_list.txt
                - 使う順にファイル名を書いておいたもの. これはあらかじめ用意するのはそれはそう.
                - gitに配置するべきもの. 実験の再現性確保のため.
        - dump @ stage 2
            - preprocessed dataと同じだと思う.

- vc_tts_template
    - logger.py: 問題なし.
    - utils.py: 問題なし.
    - train_utils.py
        - Dataset: 完全にdnntts専用. ここはでも仕方ないかも.
        - get_data_loaders: これも一部. これもまぁ仕方なし.
        - collate_fn_dnntts: これも専用関数.
        - setup: configに最高に依存している. 少しでも形式変えるとout(それは上の関数も).
    - dnntts
        - model.py: まぁ普通のmodel. 正確にはmoduleしか入ってない.
        - tts.py: inferenceといったほうが近そう. ほぼすべて特徴量の名前とかハードコード. とても使いまわせない.
        - gen.py: これも完全オリジナル.
        - multistream.py: 同様.

#### 感想
- いや, 依存しすぎ. dnnttsという結構deepのようでdeepじゃない手法なので, 複雑なのも仕方ないが...。
- 次のwavenet次第.

### wavenet
dnnttsとの違いに注目して見ていく. 実行に絡んだもののみ記載していく。

- recipes
    - common
        - fit_scaler.py: dnnttsから引き続き. @ stage 4
        今回, wavenetのoutには利用しないが, それはrun.sh内で書く. かしこい.
        フォーマットを統一するからこそ可能な正規化の使いまわし.
        - preprocess_normalize.py: 上に同様.
    - wavenet
        - run.sh: やはり最初らへんは共通. テンプレとして使えそう.
        stage -1, 0 までは完全一致.
        - config.yaml: run.shに必要. 相違点は?
        そもそもwavenetをシステムとしてみた場合, dnnttsとほぼ同じなので, 構成も確かに同じだった. 基準はまだよくわかっていない...少なくとも、「ハイパーパラメータはない」というのは確実。
        実験で頻繁に変えるとしたら↑これだしね。

        - conf: @ stage 5, 6, 7, 8
        おそらく? ここに含まれるconfはすべてtrain/model関係のハイパラ入りconfing+./run.shから渡したいものは渡せるように空白として配置という感じ. そして特にmodelは切り替えられるようにしてある. 分離.
        fastspeech2の実装でいう, preprocess.yaml+その他実行環境については./run.sh管轄のconfig.yamlにいるという感じかもしれない.
            - train_wavenet
                - config.yaml: ほとんどdnnttsのものと同じ. わかりやすさのために, 上位configで上書きする予定のものは全て何も書かないで統一したほうがいいかもしれない.
                - epoch -1 問題は, setupからの関数で行われていた.

        - preprocess_duration.py: dnnttsと同一. @ stage 1
        - preprocess_logf0.py: これも固有 @ stage 2
            思ったのが, ファイル名は全て「ファイル名-feats.npy」で統一していて, こういったpreprocessed_dataを溜めるのは,  dump以下固定, みたいな感じ. この考え方は使えそう.
        - preprocess_wavenet.py: これも同様. @ stage 3
            モデル構造にかかわるような依存も書いている(割り切れるようにしておく, とか). なのでここら辺はフォーマット(preprocessはここに配置)みたいなことだけ統一して後は毎回書く感じがいいかもね.
        - train_dnntts.py: 前回同様. @ stage 5, 6
        - train_wavenet.py: @ stage 7
            引数の名前からして違うのは意外. 確かに, criterionに渡す引数とかは毎回固定は無理だから, 仕方ないかもしれぬ...(**kwagsとかで行けるのでは?感はあるけど)
            - train_loop: ループのほうすら一般化は難しいのか? 確かに, こちらでは移動平均のパラメタを計算してそれを追加で保存したりもしていて, 一筋縄ではいかない感じ.

- vc_tts_template
    - dsp.py: degital signale processorの意味. f0抽出など, 良さげな信号処理関数盛沢山. 汎用的.
    - train_utils.py
        - collate_fn_wavenet: ここに書かなくてよくない? まったく汎用的でない.
        - moving_average_: パラメータの移動平均をとるもの. wavenetでは利用されるらしい. これは一応汎用的ではある.
    - wavenet
        - conv.py: autoregressive計算用の, buffer機能付きconv1dの実装. 普通にほかでも利用できるし使っていきたい.
            - 簡単に言えば, inference時は確かに同じ部分を計算しまくるので, 少しでも速くするために入力を覚えておく感じ.
            - weight_normはこれにはついていないことに注意.
            - forwardは, nn.Conv1dを引き継いでいるので適用可能.
        - upsample.py: upsampleしたいときに流用出来そう.　一応一般的.
            - module.pyのconvを利用している.
            - ↑このconvはconv.pyに置いたほうがよくないか?
        - modules.py: wavenetのlayerなのでほぼ使いまわせない.
            - mainの繰り返すlayerのとこだけ.
        - wavenet.py: そのまま.
        - gen.py: これは, synthesize.pyに用いられているもの.
        - tts.py: これはデモ用? 簡単にttsできるようにしている感じ. model_dirのみ指定すればok
        
#### 感想
- 依存する部分自体は変わらずだが, どういうお気持ちで作っているかが分かってきた気がする.
- というのも, 配置の問題とか. 
    - dumpにpreprocessedは置いたり, confはrun.sh, ハイパラ系はその下, とか.

### Tacotron
- recipes
    - tacotron
        - preprocess.py: ついに1つにまとまった. きれい.
        中で利用されているのはlogmelspectrogram.
        今回, frame_shiftは0.0125を利用. それが埋め込まれているのが気になる.
        - train_tacotron.py: 完成形. 美しい. これをttsのベースにしたい(一般性はないけど, 参考にするテンプレートとして完璧).
- vc_tts_template
    - tacotron
        - decoderがとにかく特殊. decoder以外はいつものフツーのやつ.
        - frontend
            - openjtalk.py: 有能関数ばかり. 汎用性大
                - pp_symbols: フルコンテキストラベルから韻律記号付きシンボル列に変えてくれる. 有能すぎ.
                JSUTの猿渡研のフルコンでは無声音を区別しないが, その調整もできる.
                - text_to_sequence: ↑ここで出てくる記号列とかも含めてid化してくれる.
            - text.py: 英語用のtext_to_sequence関数のたまり場.
    - pretrained: tts.py用. 訓練済みのモデルを保存したら, ここにある関数を使ってdownloadできる.
        配布向け. なぜかモジュールダウンロードできないし, ttsとともにいったんなしでいいかもしれない?
            - tts.pyはでも手軽に実行できるから便利なんだよな, 使いたい.
        - __init__.py: ここで関数をdefしてる. ダウンロード用やね.
    - train_utils.py
        - collate_fn_tacotron: ここでreduction factorのお世話をする.
        Datasetもdataloaderも使いまわし可能. なのでcollate_fnだけ書けば勝ち.

#### 感想
- dataset周りも一般化できるのは発見. collate_fnだけ書けば勝ち.
- genの中でsynthesisをやるけど, synthesis.pyとは違い, モデル周りだけみたいな感じ? 入力とモデルを受け取って出力を出すだけ.
synthesis.pyがデータをロードしたり, モデルを用意したりするところ.


## fastspeech2移植
お試しとして, fastspeech2をこの形式に埋め込んでみる.

### 気づき
- 一般化しすぎても, 複雑化して, espnetの二の舞になってしまう
    - あくまでも, わかりやすさ > 複雑さ にしたい.

- caffe2のwarningがうざかったら, pytorchのnightly versionをinstallすれば消える.

### 作成メモ
1. モデル部分の作成
- ここはとにかく, 引数を無限にとるようにする. configとかを介入させない.
- モジュールを分解するか? 問題
    - ほかのモデルを作る際に, 当然使いまわしの方が便利
    - 一方で, 使いまわせるレベルまで分解&一般化したらそれこそ複雑化しすぎるのではないか?
    - 中途半端にやっても無理なので, 「モジュールは完全に独立」or 「頑張って一般化」のにたく.
    - 一般化はできる気がしない. 素直に完全独立で行きましょう.
    - 別のが作りたくなったらコピペで対応.

- tensorboard
    - stepのbarが現れるか否かは何個/があるかによるっぽい.

### 要件
- 作るべきものだけをメモしておく. 逆に, ここ以外は一般化する.

- preprocess.py
    - ファイル名が`utt_id-feat.npy`である
        - これさえ守れば, フォルダを作ったりしても, run.shとdatasetで対応可能.
- collate_fn.py
    - 出力はnp. to_deviceの方で書く.
    - また, TTS, VC taskを想定しているので, group, sort機能をつける.
        - なので, 出力するのはlistということに注意.
        - reprocessを書くのが良さそう.
    - preprocessが特殊ではなく, 1つのみのファイルを扱うのであれば, collate_fnのみいじればよいが, 複数かかわるのであれば, get_dataloaderあたりから修正が必要.
    - また, partialによって引数を受け取ってからmy_appに投げることも注意.
- to_device
    - deviceにデータを渡す関数. train.py内でdef.
- model
    - 自由に作成していいが, 入力データとして, ここで使わないとしてもcollat_fnからの全データを受け取れるようにはしておく. それによって一般化できる.
    - 出力も自由.
    - 推論モードがある場合, is_inferenceという引数を受け取るか, inferenceモードを作っておくこと.
        - 今回は, evalの時にpitch targetをあげるか上げないかで, これはモデルは触る必要なし.
- loss
    - lossに関しては, 一般化する. modelと同じ階層に配置.
    - 入力: batch, output. batchはcollate_fnから出てくる全データ.
    outputは, modelから出てくる全データ.
    - 出力: loss, loss_dict. lossは全lossのsum. loss_dictは各loss名とその値が入った辞書.
        - total_lossというkeyを1つは用意すること
        - ↑修正. 最後のkeyを, best_model保存の基準にした.
            - 順序は, python3.6以降保持されるようになったらしい.
    - これを作成するだけであとはインスタンス化も自動.
- optimizer
    - originalの場合, pytorchと同じメソッド名で動くもでさえあればok.
        - ただし, lr_schedulerは, set_optimizerというmethodで
        optimizerをsetできるようにする.
        - optimizerは, set_modelというmethodでmodelをセットできるようにする.

        - 複数のoptimizer, schedulerを使いたい場合は, hifiganのように, 
        load_state_dictやstate_dictを作るように.
    - configでは, pytorchのものか作ったものかを選べるようにする.
- eval_model
    - vocoderなどは, my_appの中でインスタンス化してinferenceもmy_appで渡す.
- train_step
    - 特殊ケースの場合(hifiganのような)は, train_loopに渡すことで組み込める.