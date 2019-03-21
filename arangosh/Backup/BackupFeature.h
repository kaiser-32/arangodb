////////////////////////////////////////////////////////////////////////////////
/// DISCLAIMER
///
/// Copyright 2016 ArangoDB GmbH, Cologne, Germany
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
/// @author Dan Larkin-York
////////////////////////////////////////////////////////////////////////////////

#ifndef ARANGODB_BACKUP_BACKUP_FEATURE_H
#define ARANGODB_BACKUP_BACKUP_FEATURE_H 1

#include "ApplicationFeatures/ApplicationFeature.h"

#include "Basics/Mutex.h"
#include "Utils/ClientManager.h"

namespace arangodb {
namespace httpclient {
class SimpleHttpResult;
}

class BackupFeature : public application_features::ApplicationFeature {
 public:
  BackupFeature(application_features::ApplicationServer& server, int& exitCode);

  // for documentation of virtual methods, see `ApplicationFeature`
  virtual void collectOptions(std::shared_ptr<options::ProgramOptions>) override final;
  virtual void validateOptions(std::shared_ptr<options::ProgramOptions> options) override final;
  virtual void start() override final;

  /**
   * @brief Returns the feature name (for registration with `ApplicationServer`)
   * @return The name of the feature
   */
  static std::string featureName();

 public:
  struct Options {
    std::string credentials;
    std::string endpoint;
    bool force = false;
    bool includeSearch = true;
    std::string label = "";
    double maxWaitTime = 60.0;
    std::string name = "";
    std::string operation = "list";
    std::string timestamp = "";
    std::string uuid = "";
  };

 private:
  ClientManager _clientManager;
  int& _exitCode;
  Options _options;
};

}  // namespace arangodb

#endif
