# Vision (pphoto) 隐私政策 - GitHub Pages

本目录包含可直接用于 GitHub Pages 的隐私政策网站文件。

## 一键发布步骤（首次）

1) 在 GitHub 新建一个仓库，例如：`lazy-tech/pphoto-privacy`

2) 在本地将本目录推送到该仓库：

```bash
# 在项目根目录下执行
cd privacy-site

git init
git branch -M main
git remote add origin git@github.com:<YOUR_GITHUB_USERNAME>/pphoto-privacy.git

git add .
git commit -m "Add privacy policy site"
git push -u origin main
```

3) 在 GitHub 仓库 Settings → Pages：
- Source: 选择 "Deploy from a branch"
- Branch: 选择 `main`，Folder 选择 `/ (root)`
- 保存后等待几分钟，GitHub 会给出站点地址，如：
  `https://<YOUR_GITHUB_USERNAME>.github.io/pphoto-privacy/`

4) 将该地址填入 App Store Connect 的隐私政策 URL。

## 后续更新

修改 `index.md` 后：
```bash
cd privacy-site

git add index.md
git commit -m "Update privacy policy"
git push
```

## 可选：自定义域名
- 在仓库根目录创建 `CNAME` 文件，写入你的域名（例如 `privacy.lazy-tech.com`）
- 在 DNS 服务商处为该域名添加 CNAME 记录指向 `<YOUR_GITHUB_USERNAME>.github.io`
