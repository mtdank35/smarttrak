using Amazon.S3;
using Amazon.S3.Model;
using BasfCli.Conf;
using BasfCli.Data;
using BasfCli.Data.Tables;
using Dapper;
using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Collections.Specialized;
using System.Data.SqlClient;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Text;

namespace BasfCli.Commands.Misc
{
	[CommandHelp("Convert LangTrans table to JSON, then upload to AWS S3")]
	public class AwsLangCommand : Command
	{
		private readonly IEnumerable<Type> _commandTypes;
		private readonly TextWriter _writer;
        private string _langNmbrs;
        private ConfContainer _conf = null;
        private List<LangTrans> _rollbackLang = null;
        private const int MASTER_LANG = Language.English;

        public AwsLangCommand(IEnumerable<Type> commandTypes, TextWriter writer)
		{
			_commandTypes = commandTypes;
			_writer = writer;

            OptionSet.Add("l|lang=", "Language Code", x => _langNmbrs = x);

            // load configuration data
            var ea = System.Reflection.Assembly.GetEntryAssembly();
            FileInfo fi = new FileInfo(ea.Location);
            _conf = new ConfContainer(fi.Directory.FullName);
        }

        protected override void InnerExecute(string[] arguments)
        {
            using (var dbi = new IccmDbi(_conf.Global.IccmDbcs))
            {
                try
                {
                    _rollbackLang = dbi.LangTrans.GetList(MASTER_LANG);
                    var map = new LanguageMap();
                    if (String.IsNullOrWhiteSpace(_langNmbrs))
                    {
                        _writer.WriteLine();
                        using (new ForegroundColor(ConsoleColor.Blue))
                            _writer.WriteLine("Extracting All Languages");

                        foreach (var key in map.LangMap.Keys)
                        {
                            var lang = map.LangMap[key];
                            TransposeLang(dbi, lang);
                        }
                    }
                    else
                    {
                        // extract select language(s)
                        _writer.WriteLine();
                        using (new ForegroundColor(ConsoleColor.Blue))
                            _writer.WriteLine("Extracting Select Language(s)");
                        
                        List<int> langIds = _langNmbrs.Split(",".ToCharArray()).Select(Int32.Parse).ToList();
                        foreach (var langId in langIds)
                        {
                            if (map.LangMap.ContainsKey(langId))
                            {
                                var lang = map.LangMap[langId];
                                TransposeLang(dbi, lang);
                            }
                            else
                            {
                                using (new ForegroundColor(ConsoleColor.Red))
                                    _writer.WriteLine(String.Format("Unknown Language Id: {0:g0}", langId));
                            }
                        }
                    }
                }
                catch (Exception ex)
                {
                    using (new ForegroundColor(ConsoleColor.Red))
                        _writer.WriteLine(ex);
                }
            }
        }

        private void TransposeLang(IccmDbi dbi, LanguageInfo li)
        {
            Stopwatch s = new Stopwatch();
            s.Reset();
            s.Start();
            _writer.WriteLine(String.Format("Extracting Language [{0:g0}: {1}]", li.Id, li.Name));

            Dictionary<string, string> lang = new Dictionary<string, string>();
            List<LangTrans> things;
            // use the already queried master language data, save from having to go query again...
            if (li.Id == MASTER_LANG)
                things = _rollbackLang;
            else
                things = dbi.LangTrans.GetList(li.Id);

            foreach (var template in _rollbackLang)
            {
                // only taking 1st instance of lbl_id in case of dupes
                // might need some better rules
                if (lang.ContainsKey(template.lbl_id))
                    continue;

                if (li.Id == MASTER_LANG)
                    lang.Add(template.lbl_id, template.label_text);
                else
                {
                    var chkTranslation = things.Where(x => x.label_id == template.label_id).FirstOrDefault();
                    lang.Add(template.lbl_id, chkTranslation == null ? template.label_text : chkTranslation.label_text);
                }
            }

            UploadToAwsBucket(String.Format("{0}.json", li.FileName), JsonConvert.SerializeObject(lang));

            s.Stop();
            _writer.WriteLine(String.Format("     > {0}h {1}m {2}.{3:0}s", s.Elapsed.Hours, s.Elapsed.Minutes, s.Elapsed.Seconds, s.Elapsed.Milliseconds));
        }

        private void UploadToAwsBucket(string fName, string content)
        {
            var config = new AmazonS3Config();
            config.ServiceURL = _conf.AwsS3.ServiceURL;
            using (var client = new AmazonS3Client(_conf.AwsS3.AccessKey, _conf.AwsS3.SecretKey, config))
            {
                var request = new PutObjectRequest();
                request.BucketName = _conf.AwsS3.BucketName;
                request.Key = fName;
                //request.ContentType = "text/plain";
                request.ContentType = "application/json";
                request.ContentBody = content;
                client.PutObject(request);
            }
        }
    }
}
