////////////////////////////////////////////////////////////////////////////////
/// DISCLAIMER
///
/// Copyright 2018 ArangoDB GmbH, Cologne, Germany
///
/// Licensed under the Apache License, Version 2.0 (the "License");
/// you may not use this file except in compliance with the License.
/// You may obtain a copy of the License at
///
///     http://www.apache.org/licenses/LICENSE-2.0
///
/// Unless required by applicable law or agreed to in writing, software
/// distributed under the License is distributed on an "AS IS" BASIS,
/// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
/// See the License for the specific language governing permissions and
/// limitations under the License.
///
/// Copyright holder is ArangoDB GmbH, Cologne, Germany
///
/// @author Simon Grätzer
////////////////////////////////////////////////////////////////////////////////

#ifndef ARANGOD_NETWORK_NETWORK_FEATURE_H
#define ARANGOD_NETWORK_NETWORK_FEATURE_H 1

#include "ApplicationFeatures/ApplicationFeature.h"

#include <atomic>

namespace arangodb {
namespace network {
  class ConnectionPool;
}

class NetworkFeature final : public application_features::ApplicationFeature {
 public:
  explicit NetworkFeature(application_features::ApplicationServer& server);

  void collectOptions(std::shared_ptr<options::ProgramOptions>) override;
  void validateOptions(std::shared_ptr<options::ProgramOptions>) override;
  void prepare() override;
  void beginShutdown() override;
  void stop() override;
  void unprepare() override;
    
  /// @brief global connection pool
  static arangodb::network::ConnectionPool* pool() {
    return _poolPtr.load(std::memory_order_acquire);
  }
  
#ifdef TEST_VIRTUAL
  static void setPoolTesting(arangodb::network::ConnectionPool* pool) {
    _poolPtr.store(pool, std::memory_order_release);
  }
#endif

 protected:
  uint64_t _numIOThreads;
  uint64_t _maxOpenConnections;
  uint64_t _connectionTtlMilli;
  bool _verifyHosts;
  
  std::unique_ptr<network::ConnectionPool> _pool;
  static std::atomic<network::ConnectionPool*> _poolPtr;
};

}

#endif