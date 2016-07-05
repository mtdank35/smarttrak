using DapperExtensions.Mapper;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Basf.Data.Tables
{
    public class PourHdr
    {
        public decimal id { get; set; }

        public DateTime p_date { get; set; }

        public string p_time { get; set; }

        public decimal o_unit { get; set; }

        public string o_size { get; set; }

        public decimal col_code { get; set; }

        public string col_node { get; set; }

        public string variation { get; set; }

        public decimal? step { get; set; }

        public string paintline { get; set; }

        public string mixer_id { get; set; }

        public string ro_number { get; set; }

        public decimal pour_cost { get; set; }

        public decimal orig_cost { get; set; }

        public string rfu_flag { get; set; }

        public string rfu_name { get; set; }

        public string mix_type { get; set; }

        public string mfg { get; set; }

        public string colorcode { get; set; }

        public string std_nbr { get; set; }

        public decimal? o_col_code { get; set; }

        public string o_col_node { get; set; }

        public string colorname { get; set; }

        public decimal? voc { get; set; }

        public string customer { get; set; }

        public string booth { get; set; }

        public decimal nv_gram { get; set; }

        public decimal? wt_preamt { get; set; }

        public decimal? wt_postamt { get; set; }

        public decimal? density { get; set; }

        public decimal? vocappact { get; set; }

        public decimal? volatpct { get; set; }

        public decimal? h2owtpct { get; set; }

        public decimal? h2ovolpct { get; set; }

        public decimal? eswtpct { get; set; }

        public decimal? esvolpct { get; set; }

        public string catcode { get; set; }

        public string datacolid { get; set; }

        public decimal? sol_code { get; set; }

        public string sol_node { get; set; }

        public string voctracked { get; set; }

        public decimal? cop_code { get; set; }

        public string cop_node { get; set; }

    }

    internal class PourHdrMapper : ClassMapper<PourHdr>
    {
        public PourHdrMapper()
        {
            Table("pourhdr");
            Map(p => p.id).Key(KeyType.Assigned);
            AutoMap();
        }
    }
}
