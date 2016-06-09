using Dapper;
using DapperExtensions;
using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Linq;

namespace SlackChannelPost
{
    public static class AlertMsgRepo
    {
		public static List<AlertMsg> GetList(SqlConnection cn, IPredicate pred)
		{
			return cn.GetList<AlertMsg>(pred).ToList();
		}
		public static List<AlertMsg> GetUnsent(SqlConnection cn)
		{
			IPredicate pred = Predicates.Field<AlertMsg>(x => x.SentTmsp, Operator.Eq, new DateTime(1900,1,1));
			return cn.GetList<AlertMsg>(pred).OrderBy(x => x.RuleId).ThenBy(y => y.MsgId).ToList();
		}
		
		public static int GetUnsentCount(SqlConnection cn)
		{
			IPredicate pred = Predicates.Field<AlertMsg>(x => x.SentTmsp, Operator.Eq, new DateTime(1900, 1, 1));
			return cn.Count<AlertMsg>(pred);
		}

		public static void SetSent(SqlConnection cn, long msgId)
		{
			cn.Execute("UPDATE AlertMsg SET SentTmsp = @dt WHERE MsgId = @mid", new { mid = msgId, dt = DateTime.Now });
		}
	}
}