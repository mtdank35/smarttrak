using BasfCli.Conf;
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
	[CommandHelp("Convert LangTrans table to JSON")]
	public class LangDbCommand : Command
	{
		private readonly IEnumerable<Type> _commandTypes;
		private readonly TextWriter _writer;
        private string _langNmbrs;
        private ConfContainer _conf = null;
        private List<LangTrans> _rollbackLang = null;

        public LangDbCommand(IEnumerable<Type> commandTypes, TextWriter writer)
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
            using (var cn = new SqlConnection(_conf.Global.ConnectString))
            {
                try
                {
                    _rollbackLang = cn.Query<LangTrans>("SELECT label_id, label_text FROM LangTrans WHERE lang_code = @p1", new { p1 = Language.English }).OrderBy(x => x.label_id).ToList();
                    cn.Open();
                    var map = new LanguageMap();
                    if (String.IsNullOrWhiteSpace(_langNmbrs))
                    {
                        _writer.WriteLine();
                        using (new ForegroundColor(ConsoleColor.Blue))
                            _writer.WriteLine("Extracting All Languages");

                        foreach (var key in map.LangMap.Keys)
                        {
                            var lang = map.LangMap[key];
                            TransposeLang(cn, lang);
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
                                TransposeLang(cn, lang);
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

        private void TransposeLang(SqlConnection cn, LanguageInfo li)
        {
            Stopwatch s = new Stopwatch();
            s.Reset();
            s.Start();
            _writer.WriteLine(String.Format("Extracting Language [{0:g0}: {1}]", li.Id, li.Name));

            var things = cn.Query<LangTrans>("SELECT label_id, label_text FROM LangTrans WHERE lang_code = @p1", new { p1 = li.Id }).OrderBy(x => x.label_id).ToList();
            Dictionary<string, string> lang = new Dictionary<string, string>();
            foreach (var template in _rollbackLang)
            {
                // only taking 1st instance of lbl_id in case of dupes
                // might need some better rules
                if (lang.ContainsKey(template.lbl_id))
                    continue;

                var chkTranslation = things.Where(x => x.label_id == template.label_id).FirstOrDefault();
                lang.Add(template.lbl_id, chkTranslation == null ? template.label_text : chkTranslation.label_text);
            }

            string path = Path.Combine(_conf.Global.OutputDir, String.Format("{0}.json", li.FileName));
            File.WriteAllText(path, JsonConvert.SerializeObject(lang));

            s.Stop();
            _writer.WriteLine(String.Format("     > {0}h {1}m {2}.{3:0}s", s.Elapsed.Hours, s.Elapsed.Minutes, s.Elapsed.Seconds, s.Elapsed.Milliseconds));
        }

        private class LangTrans
        {
            [JsonIgnore]
            public int label_id { get; set; }
            public string label_text { get; set; }

            // control if we really need the 'x' prefix or not...
            [JsonIgnore]
            private bool _lblPrefix = true;

            public string lbl_id
            {
                get
                {
                    if (_lblPrefix)
                        return this.label_id == 0 ? "" : String.Format("x{0:#0}", this.label_id);
                    else
                        return this.label_id == 0 ? "" : String.Format("{0:#0}", this.label_id);
                }
            }
        }
    }
}
