using DapperExtensions.Mapper;
using System;
using System.Collections.Generic;
using System.Linq;

namespace SlackChannelPost
{
    public class Customer
    {
        public string CustId { get; set; }
        public string CustName { get; set; }
        public string CustGroup { get; set; }
        public string SiteId { get; set; }
		public string SiteType { get; set; }
    }

    internal class CustomerMapper : ClassMapper<Customer>
    {
        public CustomerMapper()
        {
            Map(p => p.CustId).Key(KeyType.Identity);
            AutoMap();
        }
    }
}