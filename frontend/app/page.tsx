"use client";

import { useState, useEffect } from "react";

// ブックマークの型定義
interface Bookmark {
  id: string;
  title: string;
  url: string;
  timestamp: number;
}

export default function Home() {
  const [url, setUrl] = useState("");
  const [title, setTitle] = useState("");
  const [status, setStatus] = useState("");
  const [bookmarks, setBookmarks] = useState<Bookmark[]>([]);
  const [loading, setLoading] = useState(true);

  // あなたのAPI GatewayのURL（末尾に /bookmarks がつくもの）
  const API_URL = "https://a1du04ebfj.execute-api.ap-northeast-1.amazonaws.com/dev/bookmarks";

  // --- データ取得関数 ---
  const fetchBookmarks = async () => {
    try {
      const response = await fetch(API_URL);
      if (!response.ok) throw new Error("取得失敗");
      const data = await response.json();
      
      // 新しい順（タイムスタンプ降順）に並び替え
      const sortedData = data.sort((a: Bookmark, b: Bookmark) => b.timestamp - a.timestamp);
      setBookmarks(sortedData);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  // ページ読み込み時に実行
  useEffect(() => {
    fetchBookmarks();
  }, []);

  // --- 送信処理 ---
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setStatus("送信中...");

    try {
      const response = await fetch(API_URL, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ url, title }),
      });

      if (response.ok) {
        setStatus("保存に成功しました！");
        setUrl("");
        setTitle("");
        // 保存成功後、リストを更新する
        fetchBookmarks();
      } else {
        setStatus("エラーが発生しました");
      }
    } catch (err) {
      setStatus("接続に失敗しました");
    }
  };

  return (
    <main className="min-h-screen p-8 bg-gray-50 text-gray-900">
      <div className="max-w-2xl mx-auto">
        <h1 className="text-3xl font-bold mb-8 text-center text-blue-600">My Tech Bookmarks</h1>
        
        {/* 入力フォーム */}
        <section className="bg-white p-6 rounded-xl shadow-sm mb-10">
          <h2 className="text-lg font-semibold mb-4">新規登録</h2>
          <form onSubmit={handleSubmit} className="space-y-4">
            <div>
              <input
                type="text"
                className="w-full p-2 border rounded"
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                placeholder="タイトル"
                required
              />
            </div>
            <div>
              <input
                type="url"
                className="w-full p-2 border rounded"
                value={url}
                onChange={(e) => setUrl(e.target.value)}
                placeholder="https://..."
                required
              />
            </div>
            <button className="w-full bg-blue-600 text-white p-2 rounded font-bold hover:bg-blue-700 transition">
              保存する
            </button>
          </form>
          {status && <p className="mt-2 text-center text-sm font-medium text-blue-500">{status}</p>}
        </section>

        {/* 一覧表示部分 */}
        <section>
          <h2 className="text-xl font-bold mb-4">保存済みリスト</h2>
          {loading ? (
            <p className="text-center">読み込み中...</p>
          ) : (
            <div className="grid gap-4">
              {bookmarks.length === 0 ? (
                <p className="text-gray-500">まだブックマークがありません。</p>
              ) : (
                bookmarks.map((bm) => (
                  <div key={bm.id} className="bg-white p-4 rounded-lg shadow-sm border-l-4 border-blue-500 hover:shadow-md transition">
                    <h3 className="font-bold text-lg">{bm.title}</h3>
                    <a 
                      href={bm.url} 
                      target="_blank" 
                      rel="noopener noreferrer" 
                      className="text-blue-500 hover:underline text-sm break-all"
                    >
                      {bm.url}
                    </a>
                  </div>
                ))
              )}
            </div>
          )}
        </section>
      </div>
    </main>
  );
}