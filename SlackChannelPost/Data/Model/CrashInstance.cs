using DapperExtensions.Mapper;
using System;
using System.Collections.Generic;
using System.Linq;

namespace SlackChannelPost
{
    public class CrashInstance
    {
        public long InstanceId { get; set; }
        public DateTime InstanceTmsp { get; set; }
        public DateTime RecordedTmsp { get; set; }
        public long CrashId { get; set; }
        public string CustId { get; set; }
        public string MachineName { get; set; }
        public string UserName { get; set; }
        public string OSPlatform { get; set; }
        public string OSFullName { get; set; }
        public string OSVersion { get; set; }
        public string ClrVersion { get; set; }
        public bool IsInteractiveUser { get; set; }
        public string Json { get; set; }
    }

    internal class CrashInstanceMapper : ClassMapper<CrashInstance>
    {
        public CrashInstanceMapper()
        {
            Map(p => p.InstanceId).Key(KeyType.Assigned);
            AutoMap();
        }
    }
}