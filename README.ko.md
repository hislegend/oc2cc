# oc2cc

> **OpenClaw → Claude Code Channels** 마이그레이션 툴킷  
> Claude Code로 텔레그램 멀티봇 운영 — API 비용 없음, OAuth 불필요.

[English](./README.md)

---

## 왜 oc2cc인가?

2026년 4월 5일, Anthropic이 서드파티 OAuth를 차단했습니다.  
OpenClaw 등 게이트웨이 제품들이 하룻밤 사이에 작동을 멈췄습니다.

**oc2cc**는 OpenClaw 멀티봇 설정을 **Claude Code Channels**로 이전하는  
실전 검증된 마이그레이션 가이드 + 스타터 킷입니다.

## 포함 내용

- ✅ 단계별 마이그레이션 가이드 (OpenClaw → CC Channels)
- ✅ 봇 워크스페이스 템플릿 (SOUL.md, IDENTITY.md, USER.md, MEMORY.md)
- ✅ Lifecycle Hooks 포함 `settings.json`
- ✅ `start-bots.sh` — tmux로 전 봇 한 번에 시작
- ✅ 트러블슈팅 가이드 (bun PATH, CLAUDE_CONFIG_DIR, Statsig, iCloud)
- ✅ 멀티계정 전략 (Claude Max 2개로 봇 4개 운영)

## 빠른 시작

```bash
git clone https://github.com/hislegend/oc2cc.git
cd oc2cc
```

[MIGRATION-GUIDE.md](./MIGRATION-GUIDE.md)를 따라 진행하세요.

## 핵심 차이점 (OpenClaw vs CC Channels)

- 인증: OAuth(차단됨) → Claude 계정 로그인
- 비용: API 사용량 → Claude Max 구독
- 멀티봇: 내장 → 봇별 CLAUDE_CONFIG_DIR 분리
- 메모리: OpenClaw 관리 → 파일 기반 (MEMORY.md)
- 규칙: AGENTS.md → .claude/rules/*.md

## 라이선스

MIT
