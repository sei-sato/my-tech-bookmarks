# 技術スタック共有ブックマーク 設計書

## 1. プロジェクト概要

ブラウザのブックマーク機能では管理しづらい  
「技術学習に特化したURL管理」を目的とした、エンジニア向けWebアプリ。

### 目的
- 技術記事・ドキュメントのストック
- 学習ステータス（未読 / 学習中 / 完了）の可視化
- 学習の抜け漏れ防止と継続支援

### ターゲット
- 自分の学習ロードマップを整理したいエンジニア
- 技術記事を大量に読むが、管理が煩雑になりがちな人

---

## 2. システム構成（Architecture）

**コスト0円運用・高セキュリティ・学習効率最大化**を目的に  
AWSのサーバーレス構成を採用する。

### システム構成図
<img src="docs/architecture/system-architecture.svg" alt="Architecture Diagram" width="800">

### 全体構成
- **Frontend**: Next.js（Static Export）
- **Hosting**: Amazon S3 + CloudFront
- **Authentication**: Amazon Cognito
- **API**: Amazon API Gateway + AWS Lambda
- **Database**: Amazon DynamoDB

### 構成の特徴
- サーバ管理不要
- スケール自動対応
- 無料枠中心での運用が可能

---

## 3. データベース設計（DynamoDB）

### テーブル定義

| 項目 | 内容 |
|---|---|
| Table Name | `MyTechBookmarks` |
| Capacity Mode | On-demand（Pay-per-request） |
| 主な用途 | ブックマーク・学習ステータス管理 |

※ アクセス頻度が低く、予測が立てにくいためオンデマンドを採用。

| 項目名 (Attribute) | 役割 | 型 | 備考 |
| :--- | :--- | :--- | :--- |
| **userId** | PK (Partition Key) | String | Cognito User ID (誰のデータか) |
| **bookmarkId** | SK (Sort Key) | String | UUID (ブックマークごとの一意識別子) |
| **url** | Data | String | 保存対象のURL |
| **title** | Data | String | ページタイトル |
| **tags** | Data | List | 技術カテゴリ (例: `["AWS", "React"]`) |
| **status** | Data | String | `unread`, `learning`, `done` |
| **createdAt** | Data | String | ISO8601 (登録日時) |

---

## 4. API定義

- 全APIエンドポイントで **Amazon Cognito 認証を必須**とする
- 未認証ユーザーからのアクセスは拒否

| Method | Path | Description | Request Body (JSON) |
| :--- | :--- | :--- | :--- |
| **POST** | `/bookmarks` | ブックマーク新規登録 | `{ "url": "...", "tags": [...] }` |
| **GET** | `/bookmarks` | ログインユーザーの一覧取得 | - |
| **PATCH** | `/bookmarks/{id}` | ステータス・タグの更新 | `{ "status": "...", "tags": [...] }` |
| **DELETE** | `/bookmarks/{id}` | ブックマークの削除 | - |

### APIの役割
- ブックマークの作成・取得・更新・削除
- 学習ステータスの更新
- 将来的な拡張（タグ、OGP取得）を考慮

---

## 5. セキュリティ設計

### 通信の保護
- CloudFront および API Gateway のデフォルトドメインを利用
- **全通信をHTTPSで暗号化**

### 認証・認可
- API Gateway に **Cognito Authorizer** を設定
- 有効なJWTトークンを持つリクエストのみ許可
- Lambdaには **最小権限のIAM Role** を付与（DynamoDB操作のみ）

### 防御策
- フロントエンド・バックエンド双方で入力バリデーションを実施
- 不正なリクエスト・想定外入力を早期に遮断

---

## 6. フェーズ分け（ロードマップ）

### Phase 1：基本機能
- 手動入力によるブックマーク登録
- 一覧表示機能
- 学習ステータス（未読 / 学習中 / 完了）の管理

### Phase 2：自動化
- LambdaによるOGP取得
  - タイトル
  - サムネイル画像
- 入力負荷の軽減

### Phase 3：学習可視化
- タグによるフィルタリング
- 学習状況ダッシュボード
- 学習進捗の俯瞰表示

---

## 7. 今後の拡張アイデア

- お気に入り・重要度設定
- 学習時間の記録
- GitHub / Zenn / Qiita 連携
- マルチデバイス対応
