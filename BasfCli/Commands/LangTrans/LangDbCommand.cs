﻿using BasfCli.Conf;
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
                    cn.Open();
                    if (String.IsNullOrWhiteSpace(_langNmbrs))
                    {
                        _writer.WriteLine();
                        using (new ForegroundColor(ConsoleColor.Red))
                            _writer.WriteLine("Extracting All Languages");

                        TransposeLanguage(cn, Language.English, "en");
                        TransposeLanguage(cn, Language.French_France, "fr");
                        // TODO: expand list per all supported languages
                    }
                    else
                    {
                        // TODO: extract a select language(s)
                        _writer.WriteLine();
                        using (new ForegroundColor(ConsoleColor.Red))
                            _writer.WriteLine(String.Format("Extracting Lang Id: {0:g0}", _langNmbrs));

                        List<int> langIds = _langNmbrs.Split(",".ToCharArray()).Select(Int32.Parse).ToList();
                        string fileName = String.Empty;
                        foreach (var langId in langIds)
                        {
                            switch (langId)
                            {
                                case Language.English:
                                    fileName = "en";
                                    break;
                                case Language.French_France:
                                    fileName = "fr";
                                    break;
                                // TODO: expand list per all supported languages
                                default:
                                    using (new ForegroundColor(ConsoleColor.Red))
                                        _writer.WriteLine(String.Format("Unknown Language Id: {0:g0}", langId));
                                    continue;
                            }

                            TransposeLanguage(cn, langId, fileName);
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

        private void TransposeLanguage(SqlConnection cn, int langId, string fileName)
        {
            var things = cn.Query<LangTrans>("SELECT label_id, label_text FROM LangTrans WHERE lang_code = @p1", new { p1 = langId }).OrderBy(x => x.label_id).ToList();
            Dictionary<string, string> lang = new Dictionary<string, string>();
            foreach (var thing in things)
                lang.Add(thing.lbl_id, thing.label_text);

            string path = Path.Combine(_conf.Global.OutputDir, String.Format("{0}.json", fileName));
            File.WriteAllText(path, JsonConvert.SerializeObject(lang));
        }

        private class LangTrans
        {
            [JsonIgnore]
            public int label_id { get; set; }
            public string label_text { get; set; }
            // if we really need the 'x' prefix, redo this part...
            //public string lbl_id { get { return this.label_id == 0 ? "" : String.Format("x{0:#0}", this.label_id); } }
            public string lbl_id { get { return this.label_id == 0 ? "" : String.Format("{0:#0}", this.label_id); } }
        }
    }
}
