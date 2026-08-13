# ZipX

Mac 压缩 / 解压 / 预览工具。Universal Binary（Apple Silicon + Intel）。

## 功能

- 压缩、解压、归档预览（ZIP / 7Z / RAR）
- 加密压缩、分卷压缩、固实压缩
- 先选文件，再选压缩或解压
- 启动自动检查更新；关于页可打开官网 / GitHub

## 官网

本地预览：

```bash
open docs/index.html
```

GitHub Pages 地址（仓库启用 Pages → Deploy from branch → `/docs`）：

https://linux503.github.io/ZipX/

## 内置引擎

- **7-Zip (`7zz`)**：已打进 App，支持 7Z 压缩/解压、RAR 解压/预览（Universal）
- **unar**：辅助解压（可选）
- **创建 RAR**：因 RARLab 版权无法内置，可在 App「设置」一键安装 `rar` 组件

第三方许可见 `Resources/bin/`。

```bash
./Scripts/build.sh
./Scripts/make_dmg.sh
./Scripts/install.sh
./Scripts/install_tools.sh   # RAR/7Z 依赖（可选）
```

## 链接

- 官网：https://linux503.github.io/ZipX/
- GitHub：https://github.com/linux503/ZipX
