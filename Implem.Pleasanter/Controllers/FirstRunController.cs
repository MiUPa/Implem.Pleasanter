using Implem.Libraries.DataSources.SqlServer;
using Implem.Libraries.Utilities;
using Implem.Pleasanter.Libraries.FirstRun;
using Implem.Pleasanter.Libraries.Html;
using Implem.Pleasanter.Libraries.HtmlParts;
using Implem.Pleasanter.Libraries.Requests;
using Implem.Pleasanter.Libraries.Responses;
using Implem.Pleasanter.Libraries.Settings;
using Implem.Pleasanter.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
namespace Implem.Pleasanter.Controllers
{
    [Authorize]
    public class FirstRunController : Controller
    {
        [HttpGet]
        public ActionResult Index()
        {
            var context = new Context();
            var log = new SysLogModel(context: context);
            var userModel = CurrentUser(context: context);
            if (userModel == null
                || !FirstRunUtilities.IsWizardRequired(
                    context: context,
                    userModel: userModel))
            {
                return Redirect(Locations.Top(context: context));
            }
            var html = new HtmlBuilder().FirstRunIndex(
                context: context,
                userModel: userModel,
                message: Request.Query["message"].ToString());
            ViewBag.HtmlBody = html;
            log.Finish(context: context, responseSize: html.Length);
            return View();
        }

        [HttpPost]
        public ActionResult Apply()
        {
            var context = new Context();
            var log = new SysLogModel(context: context);
            var userModel = CurrentUser(context: context);
            if (userModel == null
                || !FirstRunUtilities.IsWizardRequired(
                    context: context,
                    userModel: userModel))
            {
                return Redirect(Locations.Top(context: context));
            }
            // (a) Change the password while it is still the default one.
            // The built-in change-at-login flow is reused as-is; success is
            // verified by re-reading the stored password hash.
            if (FirstRunUtilities.IsDefaultPassword(userModel))
            {
                UserUtilities.ChangePasswordAtLogin(context: context);
                userModel = CurrentUser(context: context);
                if (userModel == null
                    || FirstRunUtilities.IsDefaultPassword(userModel))
                {
                    return RedirectToAction(
                        "Index",
                        new { message = "password" });
                }
            }
            // (b) Language and time zone of the administrator account.
            FirstRunUtilities.UpdateLanguageAndTimeZone(
                context: context,
                userModel: userModel,
                language: context.Forms.Data("Language"),
                timeZone: context.Forms.Data("TimeZone"));
            // (c) Optional sample site package.
            if (context.Forms.Data("ImportSample") == "yes")
            {
                if (!FirstRunUtilities.ImportSample(
                    context: context,
                    out string error))
                {
                    new SysLogModel(
                        context: context,
                        method: "FirstRun.Apply",
                        message: "FirstRun sample import failed: " + error);
                    return RedirectToAction(
                        "Index",
                        new { message = "sample" });
                }
            }
            // (d) Record completion so the wizard is never shown again.
            FirstRunUtilities.MarkCompleted(context: context);
            log.Finish(context: context, responseSize: 0);
            return Redirect(Locations.Top(context: context));
        }

        private static UserModel CurrentUser(Context context)
        {
            if (context.UserId <= 0)
            {
                return null;
            }
            var userModel = new UserModel(
                context: context,
                ss: SiteSettingsUtilities.UsersSiteSettings(context: context),
                userId: context.UserId);
            return userModel.AccessStatus == Databases.AccessStatuses.NotFound
                ? null
                : userModel;
        }
    }
}
