#pragma once

#include <string>
#include <set>
#include <map>

#include "moses/SearchNormal.h"
#include "moses/HypothesisStackNormal.h"
#include "moses/TranslationOptionCollection.h"
#include "StatefulFeatureFunction.h"
#include "FFState.h"
#include <boost/shared_ptr.hpp>

class NMT_Wrapper;
struct _object;
typedef _object PyObject;

struct Payload {
  Payload() : state_(0), logProb_(0), known_(true) {}
  Payload(PyObject* state, float logProb) : state_(state), logProb_(logProb) {}
  
  PyObject* state_;
  float logProb_;
  bool known_;
};

typedef std::map<size_t, Payload> Payloads;
typedef std::vector<std::string> Prefix;
typedef std::map<Prefix, Payloads> Prefixes;
typedef std::vector<Prefixes> PrefsByLength;

typedef std::pair<const Prefix, Payloads> PP;
typedef std::pair<const size_t, Payload> SP;

namespace Moses
{

class NeuralScoreFeature : public StatefulFeatureFunction
{
public:
  NeuralScoreFeature(const std::string &line);

  bool IsUseable(const FactorMask &mask) const {
    return true;
  }

  /*
  void InitializeForInput(ttasksptr const& ttask);
  void CleanUpAfterSentenceProcessing(ttasksptr const& ttask);
  */

  void ProcessStack(Collector& collector, size_t index);
  void BatchProcess( const std::vector<std::string>& nextWords,
    PyObject* pyContextVectors,
    const std::vector< std::string >& lastWords,
    std::vector<PyObject*>& inputStates,
    std::vector<double>& logProbs,
    std::vector<PyObject*>& nextStates, std::vector<bool>& unks);
  
  virtual const FFState* EmptyHypothesisState(const InputType &input) const;
  
  void EvaluateInIsolation(const Phrase &source
                           , const TargetPhrase &targetPhrase
                           , ScoreComponentCollection &scoreBreakdown
                           , ScoreComponentCollection &estimatedFutureScore) const;
  void EvaluateWithSourceContext(const InputType &input
                                 , const InputPath &inputPath
                                 , const TargetPhrase &targetPhrase
                                 , const StackVec *stackVec
                                 , ScoreComponentCollection &scoreBreakdown
                                 , ScoreComponentCollection *estimatedFutureScore = NULL) const;

  void EvaluateTranslationOptionListWithSourceContext(const InputType &input
      , const TranslationOptionList &translationOptionList) const;

  FFState* EvaluateWhenApplied(
    const Hypothesis& cur_hypo,
    const FFState* prev_state,
    ScoreComponentCollection* accumulator) const;
  FFState* EvaluateWhenApplied(
    const ChartHypothesis& /* cur_hypo */,
    int /* featureID - used to index the state in the previous hypotheses */,
    ScoreComponentCollection* accumulator) const;

  void SetParameter(const std::string& key, const std::string& value);

private:
  bool m_preCalc;
  std::string m_statePath;
  std::string m_modelPath;
  std::string m_wrapperPath;
  std::string m_sourceVocabPath;
  std::string m_targetVocabPath;
  size_t m_batchSize;
  size_t m_stateLength;
  size_t m_factor;
  boost::shared_ptr<NMT_Wrapper> m_wrapper;
    
  PrefsByLength m_pbl;
};

}
