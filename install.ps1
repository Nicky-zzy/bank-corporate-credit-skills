# 授信 Skill 安装 / 更新脚本（Windows PowerShell）
param(
    [switch]$Quiet,
    [string]$SkillHome = ""
)

$RepoUrl = "https://github.com/Nicky-zzy/bank-corporate-credit-skills.git"
$SrcDir  = Join-Path $env:USERPROFILE ".bank-credit-skills"

function Say($msg) { if (-not $Quiet) { Write-Host $msg } }
function Fail($msg) { Write-Error $msg; exit 1 }

# ---------- 1. 定位 skill 根目录 ----------
$stateFile = Join-Path $SrcDir ".skill_home"
if (-not $SkillHome -and (Test-Path $stateFile)) {
    $SkillHome = (Get-Content $stateFile -Raw).Trim()
}
if (-not $SkillHome) {
    $candidates = @(
        (Join-Path $env:USERPROFILE ".doubao\agent_mode\workspace\.skills"),
        (Join-Path $env:USERPROFILE ".doubao\agent_mode\.skills"),
        (Join-Path $env:USERPROFILE ".doubao\.skills")
    )
    foreach ($c in $candidates) { if (Test-Path $c) { $SkillHome = $c; break } }
}
if (-not $SkillHome) { Fail "未找到 skill 目录，请加参数 -SkillHome `"你的skill根目录`"" }
if (-not (Test-Path $SkillHome)) { Fail "目录不存在：$SkillHome" }

# ---------- 2. 取得或更新源码 ----------
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Fail "未安装 git，请先安装 Git for Windows，或将仓库 zip 解压到 $SrcDir 后重试"
}

if (Test-Path (Join-Path $SrcDir ".git")) {
    git -C $SrcDir fetch -q origin
    git -C $SrcDir checkout -q main 2>$null
    git -C $SrcDir reset -q --hard origin/main
    Say "已更新源码：$SrcDir（main）"
} elseif (Test-Path (Join-Path $SrcDir "VERSION")) {
    Say "检测到本地源码目录（非 git），跳过拉取：$SrcDir"
} else {
    git clone -q $RepoUrl $SrcDir
    Say "已克隆仓库：$SrcDir"
}

Set-Content -Path $stateFile -Value $SkillHome -Encoding UTF8

# ---------- 3. 同步每个 skill ----------
$versionFile = Join-Path $SrcDir "VERSION"
$Version = if (Test-Path $versionFile) { (Get-Content $versionFile -Raw).Trim() } else { "unknown" }

$synced = 0
Get-ChildItem (Join-Path $SrcDir "skills") -Directory | ForEach-Object {
    $skillDir = $_.FullName
    if (-not (Test-Path (Join-Path $skillDir "SKILL.md"))) { return }
    $name = $_.Name
    $target = Join-Path $SkillHome $name
    if (Test-Path $target) { Remove-Item $target -Recurse -Force }
    Copy-Item $skillDir $target -Recurse -Force
    Set-Content -Path (Join-Path $target ".installed-version") -Value $Version -Encoding UTF8
    Say "已同步 $name v$Version → $target"
    $synced++
}
if ($synced -eq 0) { Fail "仓库内未找到任何 skills/*/SKILL.md" }

Say "完成。新开一个会话后，技能列表才会重新扫描并生效。"
