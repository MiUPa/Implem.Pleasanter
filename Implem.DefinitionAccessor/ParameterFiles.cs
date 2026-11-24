using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using Implem.Libraries.Utilities;
using Implem.ParameterAccessor.Parts;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
namespace Implem.DefinitionAccessor
{
    /// <summary>
    /// Kumitate フェーズ1「設定の全UI化」の基盤。
    /// App_Data/Parameters 配下のパラメータファイルのうち、編集可能として
    /// 登録されたものについて、読み取り・検証・バックアップ付き保存を行う。
    /// 保存後は Initializer.ReloadParameters() で再起動なしに反映する。
    /// 設計メモ: workspace/goals/goal-3/hidden_files/settings-ui-design.md
    /// </summary>
    public static class ParameterFiles
    {
        public class Definition
        {
            public string Name { get; set; }
            public string Description { get; set; }
            public bool RequiresRestart { get; set; }
            public Type ParameterType { get; set; }
        }

        private static readonly List<Definition> Definitions = new List<Definition>
        {
            new Definition
            {
                Name = "Mail",
                Description = "メール送信設定（SMTP / SendGrid / Amazon SES）",
                RequiresRestart = false,
                ParameterType = typeof(Mail)
            },
            new Definition
            {
                Name = "General",
                Description = "全般設定（HTMLヘッダ、ロゴ、ポータル/ブログ等のリンク先）",
                RequiresRestart = false,
                ParameterType = typeof(General)
            },
            new Definition
            {
                Name = "Service",
                Description = "サービス設定（サービス名、タイムゾーン、既定言語、初期パスワード等。一部の項目は起動時に固定）",
                RequiresRestart = true,
                ParameterType = typeof(Service)
            },
            new Definition
            {
                Name = "Notification",
                Description = "通知設定（メール/Slack/Teams等の通知チャネル有効化）",
                RequiresRestart = false,
                ParameterType = typeof(Notification)
            },
            new Definition
            {
                Name = "Reminder",
                Description = "リマインダー設定（リマインダーの有効化と通知チャネル）",
                RequiresRestart = false,
                ParameterType = typeof(Reminder)
            },
            new Definition
            {
                Name = "Site",
                Description = "サイト設定（トップ画面の並び順、シンプルモード等）",
                RequiresRestart = false,
                ParameterType = typeof(Site)
            },
            new Definition
            {
                Name = "User",
                Description = "ユーザー設定（サイト作成・グループ管理等の許可制御）",
                RequiresRestart = false,
                ParameterType = typeof(User)
            },
            new Definition
            {
                Name = "Registration",
                Description = "ユーザー登録設定（自己登録の有効化、承認依頼先）",
                RequiresRestart = false,
                ParameterType = typeof(Registration)
            },
            new Definition
            {
                Name = "Search",
                Description = "検索設定（全文検索インデックス、ページサイズ、横断検索）",
                RequiresRestart = false,
                ParameterType = typeof(Search)
            },
            new Definition
            {
                Name = "Validation",
                Description = "入力検証設定（最大文字数、文字種の正規表現等）",
                RequiresRestart = false,
                ParameterType = typeof(Validation)
            },
            new Definition
            {
                Name = "Permissions",
                Description = "権限設定（権限パターンの数値定義）",
                RequiresRestart = false,
                ParameterType = typeof(Permissions)
            },
            new Definition
            {
                Name = "History",
                Description = "履歴設定（履歴の復元・物理削除の可否）",
                RequiresRestart = false,
                ParameterType = typeof(History)
            },
            new Definition
            {
                Name = "Deleted",
                Description = "削除済みアイテム設定（復元・物理削除の可否）",
                RequiresRestart = false,
                ParameterType = typeof(Deleted)
            },
            new Definition
            {
                Name = "Dashboard",
                Description = "ダッシュボード設定（タイムライン表示件数等）",
                RequiresRestart = false,
                ParameterType = typeof(Dashboard)
            },
            new Definition
            {
                Name = "Mobile",
                Description = "モバイル設定（レスポンシブ表示、モバイルカメラ）",
                RequiresRestart = false,
                ParameterType = typeof(Mobile)
            },
            new Definition
            {
                Name = "TextEditorUI",
                Description = "テキストエディタ設定（リッチテキストエディタのフォント等）",
                RequiresRestart = false,
                ParameterType = typeof(TextEditorUI)
            },
            new Definition
            {
                Name = "Locations",
                Description = "遷移先URL設定（トップURL、ログイン後の遷移先）",
                RequiresRestart = false,
                ParameterType = typeof(Locations)
            },
            new Definition
            {
                Name = "GroupMembers",
                Description = "グループメンバー表示形式設定",
                RequiresRestart = false,
                ParameterType = typeof(GroupMembers)
            },
            new Definition
            {
                Name = "GroupChildren",
                Description = "子グループ表示形式設定",
                RequiresRestart = false,
                ParameterType = typeof(GroupChildren)
            },
            new Definition
            {
                Name = "SysLog",
                Description = "システムログ設定（保存期間、記録対象イベント）",
                RequiresRestart = false,
                ParameterType = typeof(SysLog)
            },
            new Definition
            {
                Name = "Form",
                Description = "フォーム設定（公開フォームの有効化、添付ファイル制限）",
                RequiresRestart = false,
                ParameterType = typeof(Form)
            },
            new Definition
            {
                Name = "Script",
                Description = "スクリプト設定（サーバースクリプトの有効化、タイムアウト）",
                RequiresRestart = false,
                ParameterType = typeof(Script)
            },
            new Definition
            {
                Name = "SummarySync",
                Description = "集計同期設定（集計の再計算タイミング）",
                RequiresRestart = false,
                ParameterType = typeof(SummarySync)
            },
            new Definition
            {
                Name = "AiConnect",
                Description = "AI連携設定（Dify / OpenAI エンドポイント、RAG）",
                RequiresRestart = false,
                ParameterType = typeof(AiConnect)
            },
            new Definition
            {
                Name = "Security",
                Description = "セキュリティ設定（IP制限、特権ユーザー、パスワードポリシー等。一部は起動時に固定）",
                RequiresRestart = true,
                ParameterType = typeof(Security)
            },
            new Definition
            {
                Name = "Authentication",
                Description = "認証設定（認証プロバイダ、LDAP、SAML、パスキー。認証スキームの登録は起動時）",
                RequiresRestart = true,
                ParameterType = typeof(Authentication)
            },
            new Definition
            {
                Name = "Api",
                Description = "API設定（APIの有効化、ページサイズ、サイトあたりの上限）",
                RequiresRestart = true,
                ParameterType = typeof(Api)
            },
            new Definition
            {
                Name = "BackgroundTask",
                Description = "バックグラウンドタスク設定（実行間隔、検索インデックス作成等。一部は起動時にスケジュール化）",
                RequiresRestart = true,
                ParameterType = typeof(BackgroundTask)
            },
            new Definition
            {
                Name = "BackgroundJobs",
                Description = "バックグラウンドジョブ設定（キュー、ディスパッチ間隔、タイムアウト）",
                RequiresRestart = true,
                ParameterType = typeof(BackgroundJobs)
            },
            new Definition
            {
                Name = "RateLimit",
                Description = "レート制限設定（モード、適用パス。ポリシーは起動時に登録）",
                RequiresRestart = true,
                ParameterType = typeof(RateLimit)
            }
        };

        public static IReadOnlyList<Definition> EditableFiles => Definitions;

        public static Definition GetDefinition(string name)
        {
            return Definitions.FirstOrDefault(o => o.Name == name);
        }

        public static string FilePath(string name)
        {
            return Path.Combine(Initializer.CurrentParametersPath, name + ".json");
        }

        public static string Read(string name)
        {
            return GetDefinition(name) != null
                ? Files.Read(FilePath(name))
                : null;
        }

        public static bool Validate(string name, string json, out string error)
        {
            error = null;
            var definition = GetDefinition(name);
            if (definition == null)
            {
                error = $"編集対象外のパラメータファイルです: {name}";
                return false;
            }
            if (json.IsNullOrEmpty())
            {
                error = "内容が空です。";
                return false;
            }
            try
            {
                JObject.Parse(json);
            }
            catch (Exception e)
            {
                error = $"JSONの構文エラーです: {e.Message}";
                return false;
            }
            object data;
            try
            {
                data = JsonConvert.DeserializeObject(json, definition.ParameterType);
            }
            catch (Exception e)
            {
                error = $"設定の型チェックに失敗しました: {e.Message}";
                return false;
            }
            if (data == null)
            {
                error = "設定を読み取れませんでした。";
                return false;
            }
            return true;
        }

        public static bool Save(string name, string json, out string error)
        {
            if (!Validate(name, json, out error))
            {
                return false;
            }
            var path = FilePath(name);
            var current = Files.Read(path);
            if (current != null)
            {
                var backupPath = Path.Combine(
                    Initializer.CurrentParametersPath,
                    "Backup",
                    $"{name}.json.{DateTime.Now:yyyyMMddHHmmss}.bak");
                current.Write(backupPath);
            }
            json.Write(path);
            try
            {
                Initializer.ReloadParameters();
            }
            catch (Exception e)
            {
                error = $"保存は完了しましたが、設定の再読み込みに失敗しました: {e.Message}";
                return false;
            }
            error = null;
            return true;
        }
    }
}
