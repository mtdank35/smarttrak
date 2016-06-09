using DapperExtensions.Mapper;
using System;
using System.Collections.Generic;
using System.Linq;

namespace SlackChannelPost
{
    public class AlertMsg
    {
		public long MsgId { get; set; }
		public DateTime MsgTmsp { get; set; }
		public DateTime SentTmsp { get; set; }
		public int RuleId { get; set; }
		public long CrashId { get; set; }
		public long InstanceId { get; set; }
    }

    internal class AlertMsgMapper : ClassMapper<AlertMsg>
    {
		public AlertMsgMapper()
        {
            Map(p => p.MsgId).Key(KeyType.Assigned);
            AutoMap();
        }
    }
}