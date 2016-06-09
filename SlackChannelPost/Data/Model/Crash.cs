using DapperExtensions.Mapper;
using System;
using System.Collections.Generic;
using System.Linq;

namespace SlackChannelPost
{
    public class Crash
    {
        public long CrashId { get; set; }
        public string AppName { get; set; }
        public string AppVer { get; set; }
        public string ExType { get; set; }
        public string ExMsg { get; set; }
        public string ExSource { get; set; }
        public DateTime FirstOccurTmsp { get; set; }
        public DateTime LastOccurTmsp { get; set; }
        public int OccurCount { get; set; }
    }

    internal class CrashMapper : ClassMapper<Crash>
    {
        public CrashMapper()
        {
            Map(p => p.CrashId).Key(KeyType.Assigned);
            Map(p => p.AppName).Key(KeyType.Assigned);
            Map(p => p.AppVer).Key(KeyType.Assigned);
            Map(p => p.ExType).Key(KeyType.Assigned);
            Map(p => p.ExMsg).Key(KeyType.Assigned);
            Map(p => p.ExSource).Key(KeyType.Assigned);
            AutoMap();
        }
    }
}