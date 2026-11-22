# 银行对公授信财务分析 Skill

一套用于对公授信调查报告的财务 Skill，覆盖两个阶段：

- **阶段一**：读取近三年及近一期财报、最近一年审计报告附注，生成不超过 10 项的客户重大科目变化原因补充表；
- **阶段二**：读取客户反馈与尽调资料，交叉核对后生成可直接粘贴进授信报告的财务状况与银行融资章节。

Skill 目录：`skills/financial-analysis/SKILL.md`

---

## 一、前置条件

1. 已安装 `git`（macOS 自带；Windows 装 Git for Windows）。
2. 知道本机 skill 根目录，常见为：
   - `~/.doubao/agent_mode/workspace/.skills`
   - 其他产品形态请以实际路径为准
   - 不确定就先跑安装脚本，它会自动探测；探测不到时用 `SKILL_HOME` 指定。

## 二、安装（每人一次）

### macOS / Linux

```bash
git clone https://github.com/Nicky-zzy/bank-corporate-credit-skills.git ~/.bank-credit-skills
bash ~/.bank-credit-skills/install.sh
```

### Windows（PowerShell）

```powershell
git clone https://github.com/Nicky-zzy/bank-corporate-credit-skills.git "$env:USERPROFILE\.bank-credit-skills"
powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\.bank-credit-skills\install.ps1"
```

### 指定 skill 目录（探测失败时）

```bash
SKILL_HOME="/你的/skill根目录" bash install.sh
```

## 三、验证

1. **看文件是否落位**

```bash
ls ~/.doubao/agent_mode/workspace/.skills/financial-analysis
```

应能看到 `SKILL.md`。

2. **看版本**

```bash
cat ~/.doubao/agent_mode/workspace/.skills/financial-analysis/.installed-version
```

3. **看能否被识别**：新开一个会话，问 AI「现在有哪些技能可用」，列表里应出现 `financial-analysis`／`bank-credit-financial-workflow`。

4. **实测**：丢一份财报，说「按授信财务分析 skill 走阶段一」，看是否产出补充表。

## 四、更新（同事无需操作）

### 方案 A：定时自动拉取（推荐）

macOS / Linux：

```bash
crontab -e
# 每天早上 8 点静默同步，输出记到日志
0 8 * * * $HOME/.bank-credit-skills/install.sh --quiet >> $HOME/.bank-credit-skills/sync.log 2>&1
```

Windows（任务计划程序，每天 8:00）：

```
程序：powershell
参数：-ExecutionPolicy Bypass -File "%USERPROFILE%\.bank-credit-skills\install.ps1" --quiet
```

### 方案 B：手动一条命令

```bash
bash ~/.bank-credit-skills/install.sh
```

### 生效时机

- 改 `SKILL.md` 正文、`references/` 内容 → **下一次新会话**生效，不用重装；
- 改 `name`、`description`、目录名 → 平台要重新扫描技能列表；
- 同一次会话中途同步 → 本轮仍是旧版本。

## 五、目录结构

```
bank-corporate-credit-skills/
├── README.md            # 本文件
├── CHANGELOG.md         # 版本变更记录
├── VERSION              # 当前版本号，安装脚本据此写入 .installed-version
├── install.sh           # macOS/Linux 安装与更新
├── install.ps1          # Windows 安装与更新
└── skills/
    └── financial-analysis/
        └── SKILL.md     # Skill 主体（含使用说明与执行规则）
```

## 六、常见问题

**Q1：提示“未找到 skill 目录”？**
用 `SKILL_HOME=/实际路径 bash install.sh` 指定一次，之后脚本会记住（写入 `.skill_home`）。

**Q2：没有 git，或公司网络访问 GitHub 慢？**
下载仓库 zip 解压后执行 `bash install.sh`，脚本检测到本地已有目录会跳过克隆，直接同步。

**Q3：更新后 AI 还是旧版本？**
先确认 `.installed-version` 已变；再**新开一个会话**。技能列表在会话启动时扫描，旧会话不会热更新。

**Q4：同事能不能不改文件，只在对话里说一句“用这个 skill”？**
可以，但属于临时方案：AI 每次要去仓库现读，不入技能列表、不自动触发、慢且耗 token。日常使用仍建议安装。

**Q5：多个 skill 一起分发？**
每个 skill 放自己的子目录（`skills/<skill-name>/SKILL.md`），脚本会自动扫描并同步全部。

## 七、维护约定

- 只读使用，**不要**在本地 skill 目录改内容，否则下次同步会被覆盖；
- 更新请改仓库源文件，升 `VERSION` 与 `CHANGELOG.md`；
- 提交前自查：不含客户名称、真实报表、行内模板编号、审查口径原文等敏感内容。
