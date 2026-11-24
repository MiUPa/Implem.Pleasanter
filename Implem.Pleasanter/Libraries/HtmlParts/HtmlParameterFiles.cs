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
        public static string ParameterFilesIndex(
            this HtmlBuilder hb,
            Context context,
            string selectedName = null,
            string message = null)
        {
            if (!context.HasPrivilege)
            {
                return HtmlTemplates.Error(
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
    }
}
