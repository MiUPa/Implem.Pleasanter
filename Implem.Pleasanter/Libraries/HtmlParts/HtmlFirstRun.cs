using Implem.Libraries.Utilities;
using Implem.Pleasanter.Libraries.FirstRun;
using Implem.Pleasanter.Libraries.Html;
using Implem.Pleasanter.Libraries.Requests;
using Implem.Pleasanter.Libraries.Responses;
using Implem.Pleasanter.Libraries.Settings;
using Implem.Pleasanter.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Text;
namespace Implem.Pleasanter.Libraries.HtmlParts
{
    public static class HtmlFirstRun
    {
        public static string FirstRunIndex(
            this HtmlBuilder hb, Context context, UserModel userModel, string message)
        {
            var ja = context.Language == "ja";
            string T(string japanese, string english) => ja ? japanese : english;
            var body = new StringBuilder();
            body.Append("<div style=\"max-width:720px;margin:24px auto;\">");
            body.Append("<p>")
                .Append(T(
                    "ようこそ。最初に管理者アカウントの確認と、使い方のイメージがつかめるサンプルの読み込みを行います。",
                    "Welcome. First, confirm the administrator account settings and optionally load a sample so you can see how it works."))
                .Append("</p>");
            if (message == "password")
            {
                body.Append("<p style=\"color:#c00;\">")
                    .Append(T(
                        "パスワードを変更できませんでした。現在のパスワードを確認してください。",
                        "The password could not be changed. Please check the current password."))
                    .Append("</p>");
            }
            if (message == "sample")
            {
                body.Append("<p style=\"color:#c00;\">")
                    .Append(T(
                        "サンプルの読み込みに失敗しました。もう一度お試しいただくか、サンプルなしで完了してください。",
                        "Loading the sample failed. Please try again, or complete the setup without the sample."))
                    .Append("</p>");
            }
            body.Append("<form method=\"post\" action=\"")
                .Append(Locations.FirstRunApply(context: context))
                .Append("\">");
            body.Append("<input type=\"hidden\" name=\"Users_LoginId\" value=\"Administrator\" />");
            // (a) Password
            body.Append("<h2>")
                .Append(T("1. 管理者パスワード", "1. Administrator password"))
                .Append("</h2>");
            if (FirstRunUtilities.IsDefaultPassword(userModel))
            {
                body.Append("<p>")
                    .Append(T(
                        "初期パスワードのままです。新しいパスワードを設定してください。",
                        "The default password is still in use. Set a new password."))
                    .Append("</p>");
                body.Append("<p><label>")
                    .Append(T("現在のパスワード", "Current password"))
                    .Append("<br /><input type=\"password\" name=\"Users_Password\" autocomplete=\"current-password\" style=\"width:320px;\" /></label></p>");
                body.Append("<p><label>")
                    .Append(T("新しいパスワード", "New password"))
                    .Append("<br /><input type=\"password\" name=\"Users_ChangedPassword\" autocomplete=\"new-password\" style=\"width:320px;\" /></label></p>");
            }
            else
            {
                body.Append("<p>")
                    .Append(T(
                        "パスワードは変更済みです。",
                        "The password has already been changed."))
                    .Append("</p>");
            }
            // (b) Language and time zone
            body.Append("<h2>")
                .Append(T("2. 言語とタイムゾーン", "2. Language and time zone"))
                .Append("</h2>");
            body.Append("<p><label>")
                .Append(T("言語", "Language"))
                .Append("<br /><select name=\"Language\" style=\"width:320px;\">");
            var languageNames = new Dictionary<string, string>
            {
                { "en", "English" },
                { "zh", "Chinese" },
                { "ja", "Japanese" },
                { "de", "German" },
                { "ko", "Korean" },
                { "es", "Spanish" },
                { "vn", "Vietnamese" }
            };
            FirstRunUtilities.Languages.ForEach(language =>
                body.Append("<option value=\"")
                    .Append(language)
                    .Append("\"")
                    .Append(language == userModel.Language ? " selected" : string.Empty)
                    .Append(">")
                    .Append(languageNames.Get(language))
                    .Append("</option>"));
            body.Append("</select></label></p>");
            body.Append("<p><label>")
                .Append(T("タイムゾーン", "Time zone"))
                .Append("<br /><select name=\"TimeZone\" style=\"width:320px;\">");
            TimeZoneInfo.GetSystemTimeZones()
                .OrderBy(o => o.BaseUtcOffset)
                .ThenBy(o => o.Id)
                .ForEach(timeZone =>
                    body.Append("<option value=\"")
                        .Append(WebUtility.HtmlEncode(timeZone.Id))
                        .Append("\"")
                        .Append(timeZone.Id == userModel.TimeZone ? " selected" : string.Empty)
                        .Append(">")
                        .Append(WebUtility.HtmlEncode(timeZone.Id))
                        .Append("</option>"));
            body.Append("</select></label></p>");
            // (c) Sample
            body.Append("<h2>")
                .Append(T("3. サンプル", "3. Sample"))
                .Append("</h2>");
            body.Append("<p>")
                .Append(T(
                    "タスク管理のサンプル（フォルダ「サンプル」とレコード6件）を読み込むと、開いてすぐに一覧やガントチャートで操作感を確かめられます。不要になったら削除できます。",
                    "Loading the task-management sample (a folder named \"Sample\" with 6 records) lets you try the list and Gantt chart right away. You can delete it later."))
                .Append("</p>");
            body.Append("<p><label><input type=\"radio\" name=\"ImportSample\" value=\"yes\" checked /> ")
                .Append(T("サンプルを読み込む", "Load the sample"))
                .Append("</label></p>");
            body.Append("<p><label><input type=\"radio\" name=\"ImportSample\" value=\"no\" /> ")
                .Append(T("読み込まない", "Do not load"))
                .Append("</label></p>");
            // (d) Complete
            body.Append("<p style=\"margin-top:24px;\"><button type=\"submit\" style=\"padding:8px 24px;\">")
                .Append(T("セットアップを完了する", "Complete setup"))
                .Append("</button></p>");
            body.Append("</form>");
            body.Append("</div>");
            return hb.Template(
                context: context,
                ss: new SiteSettings(),
                view: null,
                title: T("初期セットアップ", "First-time setup"),
                useBreadcrumb: false,
                useSearch: false,
                useNavigationMenu: true,
                action: () => hb.Raw(body.ToString()))
                .ToString();
        }
    }
}
