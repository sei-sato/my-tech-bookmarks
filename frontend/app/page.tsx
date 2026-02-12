"use client";

import { useState, useEffect } from "react";

// ブックマークの型定義（imageとdescriptionを追加）
interface Bookmark {
  bookmarkId: string;
  title: string;
  url: string;
  image?: string;
  description?: string;
  timestamp: number;
}

export default function Home() {
  const [url, setUrl] = useState("");
  const [title, setTitle] = useState("");
  const [status, setStatus] = useState("");
  const [bookmarks, setBookmarks] = useState<Bookmark[]>([]);
  const [loading, setLoading] = useState(true);

  // API GatewayのURLをあなたの環境のものに書き換えてください
  const API_URL = "https://a1du04ebfj.execute-api.ap-northeast-1.amazonaws.com/dev/bookmarks";

  // --- データ取得関数 ---
  const fetchBookmarks = async () => {
    try {
      const response = await fetch(API_URL);
      if (!response.ok) throw new Error("取得失敗");
      const data = await response.json();
      
      // 新しい順（タイムスタンプ降順）にソート
      const sortedData = data.sort((a: Bookmark, b: Bookmark) => b.timestamp - a.timestamp);
      setBookmarks(sortedData);
    } catch (err) {
      console.error("Fetch error:", err);
    } finally {
      setLoading(false);
    }
  };

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
        fetchBookmarks(); // リストを再取得
      } else {
        setStatus("エラーが発生しました");
      }
    } catch (err) {
      setStatus("接続に失敗しました");
    }
  };

  return (
    <main className="min-h-screen p-4 md:p-8 bg-gray-100 text-gray-900">
      <div className="max-w-3xl mx-auto">
        <header className="mb-10 text-center">
          <h1 className="text-4xl font-extrabold text-blue-600 mb-2">Tech Bookmarks</h1>
          <p className="text-gray-500">お気に入りの技術記事をストックしよう</p>
        </header>
        
        {/* 入力フォーム */}
        <section className="bg-white p-6 rounded-2xl shadow-sm mb-12 border border-gray-200">
          <h2 className="text-xl font-bold mb-4 flex items-center">
            <span className="bg-blue-100 text-blue-600 p-1 rounded mr-2">＋</span>
            新しいブックマーク
          </h2>
          <form onSubmit={handleSubmit} className="space-y-4">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <input
                type="text"
                className="p-3 border rounded-lg border-gray-300 focus:ring-2 focus:ring-blue-500 outline-none transition"
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                placeholder="記事のタイトル"
                required
              />
              <input
                type="url"
                className="p-3 border rounded-lg border-gray-300 focus:ring-2 focus:ring-blue-500 outline-none transition"
                value={url}
                onChange={(e) => setUrl(e.target.value)}
                placeholder="https://..."
                required
              />
            </div>
            <button className="w-full bg-blue-600 text-white p-3 rounded-lg font-bold hover:bg-blue-700 transition shadow-md">
              保存する
            </button>
          </form>
          {status && <p className="mt-3 text-center text-sm font-semibold text-blue-600">{status}</p>}
        </section>

        {/* 一覧表示部分 */}
        <section>
          <div className="flex justify-between items-center mb-6">
            <h2 className="text-2xl font-bold text-gray-800">保存済みリスト</h2>
            <span className="bg-gray-200 text-gray-700 px-3 py-1 rounded-full text-sm font-medium">
              {bookmarks.length} 件
            </span>
          </div>

          {loading ? (
            <div className="text-center py-10 text-gray-500 italic">データを読み込み中...</div>
          ) : (
            <div className="grid gap-6">
              {bookmarks.length === 0 ? (
                <div className="bg-white p-10 rounded-xl text-center border-2 border-dashed border-gray-300 text-gray-400">
                  まだブックマークがありません。上のフォームから追加してください！
                </div>
              ) : (
                bookmarks.map((bm) => (
                  <div key={bm.bookmarkId} className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden hover:shadow-lg transition flex flex-col md:flex-row group">
                    {/* 左側：プレビュー画像 */}
                    <div className="md:w-56 h-40 md:h-auto overflow-hidden bg-gray-200 flex-shrink-0 relative">
                      {bm.image ? (
                        <img src={bm.image} alt="" className="w-full h-full object-cover group-hover:scale-105 transition duration-300" />
                      ) : (
                        <div className="w-full h-full flex items-center justify-center text-gray-400 text-xs">No Image</div>
                      )}
                    </div>
                    
                    {/* 右側：コンテンツ */}
                    <div className="p-5 flex flex-col justify-between flex-grow min-w-0">
                      <div>
                        <h3 className="font-bold text-xl text-gray-900 mb-2 truncate group-hover:text-blue-600 transition">
                          {bm.title}
                        </h3>
                        <p className="text-gray-600 text-sm line-clamp-2 leading-relaxed">
                          {bm.description || "説明文はありません。"}
                        </p>
                      </div>
                      <div className="mt-4 flex items-center justify-between">
                        <a 
                          href={bm.url} 
                          target="_blank" 
                          rel="noopener noreferrer" 
                          className="text-blue-500 hover:text-blue-700 text-xs font-medium truncate max-w-[80%]"
                        >
                          {bm.url}
                        </a>
                        <span className="text-[10px] text-gray-400 ml-2 shrink-0">
                          {new Date(bm.timestamp * 1000).toLocaleDateString()}
                        </span>
                      </div>
                    </div>
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