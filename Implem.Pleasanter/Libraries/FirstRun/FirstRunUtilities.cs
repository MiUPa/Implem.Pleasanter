using Implem.DefinitionAccessor;
using Implem.Libraries.DataSources.SqlServer;
using Implem.Libraries.Utilities;
using Implem.Pleasanter.Libraries.DataSources;
using Implem.Pleasanter.Libraries.Requests;
using Implem.Pleasanter.Libraries.Settings;
using Implem.Pleasanter.Libraries.SitePackages;
using Implem.Pleasanter.Models;
using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
namespace Implem.Pleasanter.Libraries.FirstRun
{
    /// <summary>
    /// Kumitate first-run wizard support.
    /// The wizard is offered only on a fresh install: the signed-in user is the
    /// initial administrator, the completion flag is not recorded yet, and the
    /// tenant does not have any site. The completion flag is stored as a row in
    /// the Parameters table with a dedicated title; the parameter patch
    /// mechanism only reads known titles, so the row is never applied as a
    /// parameter patch.
    /// </summary>
    public static class FirstRunUtilities
    {
        public const string FlagTitle = "Kumitate.FirstRun";
        public const string SampleFileName = "KumitateSampleTasks.json";
        public static readonly List<string> Languages = new List<string>
        {
            "en", "zh", "ja", "de", "ko", "es", "vn"
        };

        public static bool IsInitialAdministrator(UserModel userModel)
        {
            return userModel != null
                && userModel.LoginId == "Administrator"
                && userModel.TenantManager;
        }

        public static bool IsCompleted(Context context)
        {
            var ss = SiteSettingsUtilities.ParametersSiteSettings(context: context);
            var model = new ParameterModel(
                context: context,
                ss: ss,
                title: FlagTitle);
            return model.AccessStatus != Databases.AccessStatuses.NotFound;
        }

        public static bool HasNoSites(Context context)
        {
            return new SiteCollection(
                context: context,
                where: Rds.SitesWhere().TenantId(context.TenantId),
                top: 1).Count == 0;
        }

        public static bool IsWizardRequired(Context context, UserModel userModel)
        {
            return IsInitialAdministrator(userModel)
                && !IsCompleted(context: context)
                && HasNoSites(context: context);
        }

        public static bool IsDefaultPassword(UserModel userModel)
        {
            return userModel.Password == Parameters.Service.DefaultPassword.Sha512Cng();
        }

        public static void MarkCompleted(Context context)
        {
            var ss = SiteSettingsUtilities.ParametersSiteSettings(context: context);
            var model = new ParameterModel(
                context: context,
                ss: ss,
                title: FlagTitle);
            if (model.AccessStatus == Databases.AccessStatuses.NotFound)
            {
                model.Body = "{{\"CompletedAt\":\""
                    + DateTime.Now.ToString("yyyy-MM-ddTHH:mm:ss")
                    + "\",\"WizardVersion\":1}";
                // get: false — reloading the row through the parameter
                // editor's model path is unnecessary here.
                model.Create(
                    context: context,
                    ss: ss,
                    get: false);
            }
        }

        public static void UpdateLanguageAndTimeZone(
            Context context, UserModel userModel, string language, string timeZone)
        {
            var param = Rds.UsersParam();
            var changed = false;
            if (Languages.Contains(language) && language != userModel.Language)
            {
                param.Language(language);
                changed = true;
            }
            if (!timeZone.IsNullOrEmpty()
                && timeZone != userModel.TimeZone
                && TimeZoneInfo.GetSystemTimeZones().Any(o => o.Id == timeZone))
            {
                param.TimeZone(timeZone);
                changed = true;
            }
            if (changed)
            {
                Repository.ExecuteNonQuery(
                    context: context,
                    statements: Rds.UpdateUsers(
                        where: Rds.UsersWhereDefault(
                            context: context,
                            userModel: userModel),
                        param: param));
            }
        }

        public static bool ImportSample(Context context, out string error)
        {
            error = null;
            try
            {
                var path = Path.Combine(
                    Environments.CurrentDirectoryPath,
                    "App_Data",
                    "Samples",
                    SampleFileName);
                if (!System.IO.File.Exists(path))
                {
                    error = "Sample file was not found: " + path;
                    return false;
                }
                SitePackage sitePackage;
                using (var streamReader = new StreamReader(path, Encoding.UTF8))
                using (var reader = new JsonTextReader(streamReader))
                {
                    sitePackage = new JsonSerializer().Deserialize<SitePackage>(reader);
                }
                if (sitePackage == null)
                {
                    error = "Sample file could not be read.";
                    return false;
                }
                var ss = SiteSettingsUtilities.SitesSiteSettings(
                    context: context,
                    siteId: 0);
                var result = Utilities.ImportSitePackage(
                    context: context,
                    ss: ss,
                    sitePackage: sitePackage,
                    includeData: true,
                    includeSitePermission: false,
                    includeRecordPermission: false,
                    includeColumnPermission: false,
                    includeNotifications: false,
                    includeReminders: false);
                return result != null && result.Contains("\"Href\"");
            }
            catch (Exception e)
            {
                error = e.Message;
                return false;
            }
        }
    }
}
