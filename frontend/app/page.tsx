"use client";

import { useState, useEffect } from "react";

interface Bookmark {
  bookmarkId: string;
  title: string;
  url: string;
  image?: string;
  description?: string;
  status: 'unread' | 'learning' | 'done';
  timestamp: number;
}

type StatusType = 'unread' | 'learning' | 'done';

export default function Home() {
  const [url, setUrl] = useState("");
  const [statusMsg, setStatusMsg] = useState("");
  const [bookmarks, setBookmarks] = useState<Bookmark[]>([]);
  const [loading, setLoading] = useState(true);
  
  const [activeTab, setActiveTab] = useState<StatusType>('unread');

  const API_URL = "https://a1du04ebfj.execute-api.ap-northeast-1.amazonaws.com/dev/bookmarks";

  const fetchBookmarks = async () => {
    try {
      const response = await fetch(API_URL);
      if (!response.ok) throw new Error("取得失敗");
      const data = await response.json();
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

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setStatusMsg("保存中...");
    try {
      // タイトルは送らず、URLのみをPOSTする
      const response = await fetch(API_URL, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ url }), 
      });

      if (response.ok) {
        setStatusMsg("保存に成功しました！");
        setUrl("");
        fetchBookmarks();
      } else {
        setStatusMsg("エラーが発生しました。URLを修正してください。");
      }
    } catch (err) {
      setStatusMsg("接続に失敗しました");
    }
  };

  const handleDelete = async (bookmarkId: string) => {
    if (!confirm("本当にこのブックマークを削除しますか？")) return;
    try {
      const response = await fetch(`${API_URL}/${bookmarkId}`, {
        method: "DELETE",
      });
      if (response.ok) {
        setBookmarks(bookmarks.filter((bm) => bm.bookmarkId !== bookmarkId));
      } else {
        alert("削除に失敗しました");
      }
    } catch (err) {
      console.error("Delete error:", err);
    }
  };

  const handleUpdateStatus = async (bookmarkId: string, currentStatus: string) => {
    const statusOrder: Record<string, StatusType> = {
      unread: 'learning',
      learning: 'done',
      done: 'unread'
    };
    const nextStatus = statusOrder[currentStatus] || 'unread';

    try {
      const response = await fetch(`${API_URL}/${bookmarkId}`, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ status: nextStatus }),
      });

      if (response.ok) {
        setBookmarks(bookmarks.map(bm => 
          bm.bookmarkId === bookmarkId ? { ...bm, status: nextStatus } : bm
        ));
      }
    } catch (err) {
      console.error("Update error:", err);
    }
  };

  const filteredBookmarks = bookmarks.filter(bm => bm.status === activeTab);

  return (
    <main className="min-h-screen p-4 md:p-8 bg-gray-100 text-gray-900">
      <div className="max-w-3xl mx-auto">
        <header className="mb-10 text-center">
          <h1 className="text-4xl font-extrabold text-blue-600 mb-2">Tech Bookmarks</h1>
          <p className="text-gray-500">URLだけで自動ブックマーク</p>
        </header>
        
        <section className="bg-white p-6 rounded-2xl shadow-sm mb-12 border border-gray-200">
          <h2 className="text-xl font-bold mb-4 flex items-center">
            <span className="bg-blue-100 text-blue-600 p-1 rounded mr-2">🔗</span>
            新しいブックマーク
          </h2>
          {/* フォームを横並びのシンプルな構成に変更 */}
          <form onSubmit={handleSubmit} className="flex flex-col md:flex-row gap-3">
            <input
              type="url"
              className="flex-grow p-3 border rounded-lg border-gray-300 focus:ring-2 focus:ring-blue-500 outline-none transition"
              value={url}
              onChange={(e) => setUrl(e.target.value)}
              placeholder="https://example.com/article"
              required
            />
            <button className="bg-blue-600 text-white px-8 py-3 rounded-lg font-bold hover:bg-blue-700 transition shadow-md shrink-0">
              追加
            </button>
          </form>
          {statusMsg && <p className="mt-3 text-center text-sm font-semibold text-blue-600">{statusMsg}</p>}
        </section>

        <section>
          <div className="flex justify-between items-center mb-6">
            <h2 className="text-2xl font-bold text-gray-800">保存済みリスト</h2>
            <span className="bg-gray-200 text-gray-700 px-3 py-1 rounded-full text-sm font-medium">
              合計 {bookmarks.length} 件
            </span>
          </div>

          <div className="flex space-x-2 mb-6 bg-gray-200 p-1 rounded-xl">
            {(['unread', 'learning', 'done'] as const).map((status) => (
              <button
                key={status}
                onClick={() => setActiveTab(status)}
                className={`flex-1 py-2 text-sm font-bold rounded-lg transition-all duration-200 ${
                  activeTab === status
                    ? "bg-white text-blue-600 shadow-sm"
                    : "text-gray-500 hover:text-gray-700 hover:bg-gray-300/50"
                }`}
              >
                {status === 'unread' ? '未読' : status === 'learning' ? '学習中' : '完了'}
                <span className={`ml-2 text-xs px-1.5 py-0.5 rounded-full ${
                  activeTab === status ? "bg-blue-100" : "bg-gray-300"
                }`}>
                  {bookmarks.filter(b => b.status === status).length}
                </span>
              </button>
            ))}
          </div>

          {loading ? (
            <div className="text-center py-10 text-gray-500 italic">データを読み込み中...</div>
          ) : (
            <div className="grid gap-6">
              {filteredBookmarks.length === 0 ? (
                <div className="bg-white p-10 rounded-xl text-center border-2 border-dashed border-gray-300 text-gray-400">
                  {activeTab === 'unread' ? '未読の記事はありません。' : 
                   activeTab === 'learning' ? '現在学習中の記事はありません。' : 
                   '完了した記事はありません。'}
                </div>
              ) : (
                filteredBookmarks.map((bm) => (
                  <div key={bm.bookmarkId} className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden hover:shadow-lg transition flex flex-col md:flex-row group md:h-36">
                    
                    <div className="w-full md:w-48 h-40 md:h-full overflow-hidden bg-gray-50 flex-shrink-0 relative border-b md:border-b-0 md:border-r border-gray-100 flex items-center justify-center p-2">
                      {bm.image ? (
                        <img 
                          src={bm.image} 
                          alt="" 
                          className="w-full h-full object-contain transition duration-500 group-hover:scale-105" 
                          onError={(e) => {
                            (e.target as HTMLImageElement).src = "https://via.placeholder.com/400x300?text=No+Image";
                          }}
                        />
                      ) : (
                        <div className="w-full h-full flex flex-col items-center justify-center text-gray-300">
                          <svg xmlns="http://www.w3.org/2000/svg" className="h-8 w-8 mb-1 opacity-20" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
                          </svg>
                        </div>
                      )}
                    </div>
                    
                    <div className="p-4 flex flex-col justify-between flex-grow min-w-0 h-full">
                      <div className="overflow-hidden">
                        <div className="flex justify-between items-start mb-1 gap-2">
                          <h3 className="font-bold text-base text-gray-900 truncate group-hover:text-blue-600 transition">
                            {/* タイトルがない場合の表示を考慮 */}
                            {bm.title || "読み込み中..."}
                          </h3>
                          <button 
                            onClick={() => handleUpdateStatus(bm.bookmarkId, bm.status || 'unread')}
                            className={`px-2 py-1 rounded text-[10px] font-bold uppercase transition shrink-0 ${
                              bm.status === 'done' ? 'bg-green-100 text-green-600 border border-green-200' :
                              bm.status === 'learning' ? 'bg-yellow-100 text-yellow-600 border border-yellow-200' :
                              'bg-gray-100 text-gray-500 border border-gray-200'
                            }`}
                          >
                            {bm.status === 'done' ? '完了' : bm.status === 'learning' ? '学習中' : '未読'}
                          </button>
                        </div>
                        <p className="text-gray-600 text-xs line-clamp-2 leading-relaxed">
                          {bm.description || "説明文はありません。"}
                        </p>
                      </div>

                      <div className="mt-2 flex items-center justify-between">
                        <a 
                          href={bm.url} 
                          target="_blank" 
                          rel="noopener noreferrer" 
                          className="text-blue-500 hover:text-blue-700 text-[10px] font-medium truncate max-w-[65%]"
                        >
                          {bm.url}
                        </a>
                        
                        <div className="flex items-center space-x-2">
                          <span className="text-[10px] text-gray-400 shrink-0">
                            {new Date(bm.timestamp * 1000).toLocaleDateString()}
                          </span>
                          <button 
                            onClick={() => handleDelete(bm.bookmarkId)}
                            className="text-gray-400 hover:text-red-500 transition-colors p-1"
                          >
                            <svg xmlns="http://www.w3.org/2000/svg" className="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                            </svg>
                          </button>
                        </div>
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