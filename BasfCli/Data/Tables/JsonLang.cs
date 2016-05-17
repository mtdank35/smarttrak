using DapperExtensions.Mapper;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BasfCli.Data.Tables
{
    public class JsonLang
    {
        public int LangId { get; set; }
        public string LangDescr { get; set; }
        public string LangTranslation { get; set; }
    }

    internal class JsonLangMapper : ClassMapper<JsonLang>
    {
        public JsonLangMapper()
        {
            Map(p => p.LangId).Key(KeyType.Assigned);
            AutoMap();
        }
    }
}
