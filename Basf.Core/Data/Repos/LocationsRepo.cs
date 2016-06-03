using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Linq;
using Dapper;
using DapperExtensions;
using Basf.Data.Tables;
using DapperExtensions.Sql;
using DapperExtensions.Mapper;
using System.Reflection;

namespace Basf.Data.Repos
{
    public class LocationsRepo
    {
        private IDatabase _db;
        public LocationsRepo(IDatabase db)
        {
            _db = db;
        }

        public Locations Get(int locId, SqlTransaction tx = null)
        {
            var entity = _db.Get<Locations>(new { seqId = locId }, tx);
            return entity;
        }

        public List<Locations> GetList(IPredicate pred, SqlTransaction tx = null)
        {
            return _db.Connection.GetList<Locations>(pred, null, tx).ToList();
        }

        public void Insert(Locations entity, SqlTransaction tx = null)
        {
            _db.Insert(entity, tx);
        }

        public bool Update(Locations entity, SqlTransaction tx = null)
        {
            return _db.Update(entity, tx);
        }

        public void Upsert(Locations entity, SqlTransaction tx = null)
        {
            if (!Update(entity, tx))
                Insert(entity, tx);
        }

        public void Delete(Locations entity, SqlTransaction tx = null)
        {
            _db.Delete(entity, tx);
        }
    }
}
