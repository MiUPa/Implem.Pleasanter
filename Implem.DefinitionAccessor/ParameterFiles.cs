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
