# リリース手順

## リリース方法

`Makefile.PL` の `VERSION` を更新し、バージョンタグを push します。

```bash
git tag v2.1.4
git push origin v2.1.4
```

GitHub Actions が以下を自動実行します：

1. POD HTML によるAPIドキュメント生成（`pod2html`）
2. GitHub Releases にアーカイブを公開（`cti-perl-{VERSION}.zip` / `.tar.gz`）
3. GitHub Pages にドキュメントをデプロイ

## CPAN への公開（手動）

```bash
perl Makefile.PL
make dist
cpan-upload CTI-{VERSION}.tar.gz
```

PAUSE アカウントが必要です（https://pause.perl.org/）。

## ドキュメント

- **GitHub Pages**: https://zamasoftnet.github.io/cti.perl/
- リリース時に自動更新
