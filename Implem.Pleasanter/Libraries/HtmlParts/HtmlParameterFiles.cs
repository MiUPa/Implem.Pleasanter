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
            string message = null)
        {
            if (!context.HasPrivilege)
            {
                return HtmlTemplates.Error(
                    context: context,
                    errorData: new ErrorData(type: Error.Types.HasNotPermission));
            }
            var ss = new SiteSettings();
            var definition = ParameterFiles.EditableFiles.FirstOrDefault();
            var json = definition != null
                ? ParameterFiles.Read(definition.Name) ?? string.Empty
                : string.Empty;
            var body = new System.Text.StringBuilder();
            body.Append("<div style=\"padding:16px;\">");
            if (!message.IsNullOrEmpty())
            {
                body.Append("<p style=\"color:#c00;\">")
                    .Append(HttpUtility.HtmlEncode(message))
                    .Append("</p>");
            }
            if (definition != null)
            {
                body.Append("<h2>")
                    .Append(HttpUtility.HtmlEncode(definition.Name))
                    .Append(".json</h2>");
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
                    .Append("<button type=\"submit\">保存して再読み込み</button>")
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
