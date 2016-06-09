using DapperExtensions.Mapper;
using System;
using System.Collections.Generic;
using System.Linq;

namespace SlackChannelPost
{
    public class AlertMsgTarget
    {
		public string RuleName{ get; set; }
		public int TargetId { get; set; }
		public string TargetName { get; set; }
		public int TargetType { get; set; }
		public string TargetAddr { get; set; }
    }
}