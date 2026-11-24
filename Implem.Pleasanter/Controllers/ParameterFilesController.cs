using Implem.DefinitionAccessor;
using Implem.Pleasanter.Libraries.Html;
using Implem.Pleasanter.Libraries.HtmlParts;
using Implem.Pleasanter.Libraries.Requests;
using Implem.Pleasanter.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
namespace Implem.Pleasanter.Controllers
{
    [Authorize]
    public class ParameterFilesController : Controller
    {
        [HttpGet]
        public ActionResult Index()
        {
            var context = new Context();
            var log = new SysLogModel(context: context);
            var html = new HtmlBuilder().ParameterFilesIndex(
                context: context,
                selectedName: Request.Query["name"].ToString(),
                message: Request.Query["message"].ToString());
            ViewBag.HtmlBody = html;
            log.Finish(context: context, responseSize: html.Length);
            return View();
        }

        [HttpPost]
        public ActionResult Update()
        {
            var context = new Context();
            var log = new SysLogModel(context: context);
            if (!context.HasPrivilege)
            {
                log.Finish(context: context, responseSize: 0);
                return RedirectToAction(nameof(Index));
            }
            var name = Request.Form["name"].ToString();
            var body = Request.Form["body"].ToString();
            var saved = ParameterFiles.Save(name, body, out var error);
            if (saved)
            {
                new SysLogModel(
                    context: context,
                    method: nameof(Update),
                    message: $"Parameter file updated: {name}.json",
                    sysLogType: SysLogModel.SysLogTypes.Info);
            }
            var definition = ParameterFiles.GetDefinition(name);
            var message = saved
                ? definition?.RequiresRestart == true
                    ? $"{name}.json を保存しました。再起動後に完全に反映されます。"
                    : $"{name}.json を保存し、設定を再読み込みしました。"
                : error;
            log.Finish(context: context, responseSize: 0);
            return RedirectToAction(nameof(Index), new { name, message });
        }

        [HttpPost]
        public ActionResult Bootstrap()
        {
            var context = new Context();
            var log = new SysLogModel(context: context);
            if (!HtmlParameterFiles.CanBootstrapPrivilegedUser(context: context))
            {
                log.Finish(context: context, responseSize: 0);
                return RedirectToAction(nameof(Index));
            }
            var registered = ParameterFiles.BootstrapPrivilegedUser(
                context.LoginId,
                out var error);
            if (registered)
            {
                new SysLogModel(
                    context: context,
                    method: nameof(Bootstrap),
                    message: $"First privileged user registered: {context.LoginId}",
                    sysLogType: SysLogModel.SysLogTypes.Info);
            }
            var message = registered
                ? $"特権ユーザーに {context.LoginId} を登録しました。"
                : error;
            log.Finish(context: context, responseSize: 0);
            return RedirectToAction(nameof(Index), new { message });
        }
    }
}
