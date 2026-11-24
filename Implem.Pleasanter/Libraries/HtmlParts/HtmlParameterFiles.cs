using System.Linq;
using System.Web;
using Implem.DefinitionAccessor;
using Implem.Libraries.Utilities;
using Implem.Pleasanter.Libraries.General;
using Implem.Pleasanter.Libraries.Html;
using Implem.Pleasanter.Libraries.Requests;
using Implem.Pleasanter.Libraries.Responses;
using Implem.Pleasanter.Libraries.Settings;
namespace Implem.Pleasanter.Libraries.HtmlParts
{
    public static class HtmlParameterFiles
    {
        /// <summary>
        /// 最初の特権ユーザーを GUI から登録できる状態かどうか。
        /// 特権ユーザーが未登録で、ログイン中ユーザーがテナント管理者
        /// （＝管理画面の前提権限を持つ管理者）の場合にのみ true。
        /// 登録済みの環境や、管理者でないユーザーでは常に false。
        /// </summary>
        public static bool CanBootstrapPrivilegedUser(Context context)
        {
            return context.Authenticated
                && context.User?.TenantManager == true
                && !context.HasPrivilege
                && ParameterFiles.PrivilegedUsersIsEmpty();
        }

        public static string ParameterFilesIndex(
            this HtmlBuilder hb,
            Context context,
            string selectedName = null,
            string message = null)
        {
            if (!context.HasPrivilege)
            {
                return CanBootstrapPrivilegedUser(context: context)
                    ? BootstrapIndex(
                        hb: hb,
                        context: context,
                        message: message)
                    : HtmlTemplates.Error(
                        context: context,
                        errorData: new ErrorData(type: Error.Types.HasNotPermission));
            }
            var ss = new SiteSettings();
            var definition = ParameterFiles.GetDefinition(selectedName)
                ?? ParameterFiles.EditableFiles.FirstOrDefault();
            var body = new System.Text.StringBuilder();
            body.Append("<div style=\"padding:16px;\">");
            if (!message.IsNullOrEmpty())
            {
                body.Append("<p style=\"color:#c00;\">")
                    .Append(HttpUtility.HtmlEncode(message))
                    .Append("</p>");
            }
            body.Append("<h2>パラメータファイル</h2>");
            body.Append("<ul>");
            foreach (var item in ParameterFiles.EditableFiles)
            {
                body.Append("<li>");
                if (definition != null && item.Name == definition.Name)
                {
                    body.Append("<strong>")
                        .Append(HttpUtility.HtmlEncode(item.Name))
                        .Append(".json</strong>");
                }
                else
                {
                    body.Append("<a href=\"/parameterfiles/index?name=")
                        .Append(HttpUtility.UrlEncode(item.Name))
                        .Append("\">")
                        .Append(HttpUtility.HtmlEncode(item.Name))
                        .Append(".json</a>");
                }
                body.Append(" - ")
                    .Append(HttpUtility.HtmlEncode(item.Description))
                    .Append(item.RequiresRestart
                        ? "（再起動で反映）"
                        : "（即時反映）")
                    .Append("</li>");
            }
            body.Append("</ul>");
            if (definition != null)
            {
                var json = ParameterFiles.Read(definition.Name) ?? string.Empty;
                body.Append("<h3>")
                    .Append(HttpUtility.HtmlEncode(definition.Name))
                    .Append(".json</h3>");
                body.Append("<p>")
                    .Append(HttpUtility.HtmlEncode(definition.Description))
                    .Append(definition.RequiresRestart
                        ? "（保存後、再起動で反映されます）"
                        : "（保存後、再起動なしで反映されます）")
                    .Append("</p>");
                body.Append("<form method=\"post\" action=\"/parameterfiles/update\">");
                body.Append("<input type=\"hidden\" name=\"name\" value=\"")
                    .Append(HttpUtility.HtmlEncode(definition.Name))
                    .Append("\" />");
                body.Append("<textarea name=\"body\" rows=\"30\" style=\"width:100%;font-family:monospace;\">")
                    .Append(HttpUtility.HtmlEncode(json))
                    .Append("</textarea>");
                body.Append("<div style=\"margin-top:8px;\">")
                    .Append(definition.RequiresRestart
                        ? "<button type=\"submit\">保存</button>"
                        : "<button type=\"submit\">保存して再読み込み</button>")
                    .Append("</div>");
                body.Append("</form>");
            }
            body.Append("</div>");
            return hb.Template(
                context: context,
                ss: ss,
                view: null,
                title: "パラメータファイル",
                useNavigationMenu: true,
                action: () => hb.Raw(body.ToString()))
                    .ToString();
        }

        private static string BootstrapIndex(
            HtmlBuilder hb,
            Context context,
            string message = null)
        {
            var ss = new SiteSettings();
            var loginId = HttpUtility.HtmlEncode(context.LoginId);
            var body = new System.Text.StringBuilder();
            body.Append("<div style=\"padding:16px;\">");
            if (!message.IsNullOrEmpty())
            {
                body.Append("<p style=\"color:#c00;\">")
                    .Append(HttpUtility.HtmlEncode(message))
                    .Append("</p>");
            }
            body.Append("<h2>パラメータファイル</h2>");
            body.Append("<h3>最初の特権ユーザーの登録</h3>");
            body.Append("<p>現在、特権ユーザー（Security.json の PrivilegedUsers）が未登録のため、パラメータファイルの編集画面を開けません。</p>");
            body.Append("<p>特権ユーザーは、この画面を含む管理機能を利用できるユーザーを決める設定です。ファイルの手編集は不要で、テナント管理者であるあなた自身を、最初の特権ユーザーとしてここから登録できます。</p>");
            body.Append("<p>登録すると Security.json に保存され（保存時にバックアップも作成されます）、以降は登録された特権ユーザーのみがこの画面を開けます。</p>");
            body.Append("<p>登録するログインID: <strong>")
                .Append(loginId)
                .Append("</strong></p>");
            body.Append("<form method=\"post\" action=\"/parameterfiles/bootstrap\">");
            body.Append("<div style=\"margin-top:8px;\">")
                .Append("<button type=\"submit\">")
                .Append(loginId)
                .Append(" を特権ユーザーとして登録する</button>")
                .Append("</div>");
            body.Append("</form>");
            body.Append("</div>");
            return hb.Template(
                context: context,
                ss: ss,
                view: null,
                title: "パラメータファイル",
                useNavigationMenu: true,
                action: () => hb.Raw(body.ToString()))
                    .ToString();
        }
    }
}
