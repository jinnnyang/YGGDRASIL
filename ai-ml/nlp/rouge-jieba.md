---
title: "使用 rouge_score 与 jieba 计算中文 ROUGE"
slug: "rouge-jieba"
description: "演示如何使用 jieba 分词配合 rouge_score 计算中文文本的 ROUGE 评价指标，并给出可复用的实现代码片段。"
author: "jinnyang"
date: 2023-11-22
categories:
  - ai-ml
  - nlp
tags:
  - rouge
  - jieba
  - chinese-rouge
  - nlp
  - evaluation
status: published
---

## 需求概述
Rouge评分是依赖分词实现的，而中文鲜有分词的说法。

## 实现代码
实现代码如下
```python
import jieba
from rouge_score.rouge_scorer import _create_ngrams, _score_ngrams, _score_lcs

def words_rouge(_input, _ideal):
    # Tokenize
    input_tokens = list(jieba.cut(_input.replace(" ", "")))
    ideal_tokens = list(jieba.cut(_ideal.replace(" ", "")))
    
    # N-Grams
    input_ngrams_1= _create_ngrams(input_tokens, 1)
    ideal_ngrams_1= _create_ngrams(ideal_tokens, 1)
    input_ngrams_2= _create_ngrams(input_tokens, 2)
    ideal_ngrams_2= _create_ngrams(ideal_tokens, 2)

    # Rouge score.
    rouge_1 = _score_ngrams(ideal_ngrams_1, input_ngrams_1)
    rouge_2 = _score_ngrams(ideal_ngrams_2, input_ngrams_2)
    rouge_l = _score_lcs(ideal_tokens, input_tokens)

    # Result
    return {"rouge-1":rouge_1, "rouge-2": rouge_2, "rouge-l": rouge_l}

if __name__ == "__main__":
    scores = words_rouge('吃葡萄不吐葡萄皮', '不吃葡萄倒吐葡萄皮')
    print(scores)
```

为了方便自定义修改，它依赖的一些函数如下
```python
def _create_ngrams(tokens, n):
  """Creates ngrams from the given list of tokens.

  Args:
    tokens: A list of tokens from which ngrams are created.
    n: Number of tokens to use, e.g. 2 for bigrams.
  Returns:
    A dictionary mapping each bigram to the number of occurrences.
  """

  ngrams = collections.Counter()
  for ngram in (tuple(tokens[i:i + n]) for i in range(len(tokens) - n + 1)):
    ngrams[ngram] += 1
  return ngrams

def _score_lcs(target_tokens, prediction_tokens):
  """Computes LCS (Longest Common Subsequence) rouge scores.

  Args:
    target_tokens: Tokens from the target text.
    prediction_tokens: Tokens from the predicted text.
  Returns:
    A Score object containing computed scores.
  """

  if not target_tokens or not prediction_tokens:
    return scoring.Score(precision=0, recall=0, fmeasure=0)

  # Compute length of LCS from the bottom up in a table (DP appproach).
  lcs_table = _lcs_table(target_tokens, prediction_tokens)
  lcs_length = lcs_table[-1][-1]

  precision = lcs_length / len(prediction_tokens)
  recall = lcs_length / len(target_tokens)
  fmeasure = scoring.fmeasure(precision, recall)

  return scoring.Score(precision=precision, recall=recall, fmeasure=fmeasure)

def _score_ngrams(target_ngrams, prediction_ngrams):
  """Compute n-gram based rouge scores.

  Args:
    target_ngrams: A Counter object mapping each ngram to number of
      occurrences for the target text.
    prediction_ngrams: A Counter object mapping each ngram to number of
      occurrences for the prediction text.
  Returns:
    A Score object containing computed scores.
  """

  intersection_ngrams_count = 0
  for ngram in six.iterkeys(target_ngrams):
    intersection_ngrams_count += min(target_ngrams[ngram],
                                     prediction_ngrams[ngram])
  target_ngrams_count = sum(target_ngrams.values())
  prediction_ngrams_count = sum(prediction_ngrams.values())

  precision = intersection_ngrams_count / max(prediction_ngrams_count, 1)
  recall = intersection_ngrams_count / max(target_ngrams_count, 1)
  fmeasure = scoring.fmeasure(precision, recall)

  return scoring.Score(precision=precision, recall=recall, fmeasure=fmeasure)
```

实际使用中应该使用`evaluate`库提供的实现，实例见[[Transformers结合Trainer和WanDB实现训练日志管理]]中指标计算。


[Transformers结合Trainer和WanDB实现训练日志管理]: ../../inputs/notes/Snipptes/Python/Transformers%E7%BB%93%E5%90%88Trainer%E5%92%8CWanDB%E5%AE%9E%E7%8E%B0%E8%AE%AD%E7%BB%83%E6%97%A5%E5%BF%97%E7%AE%A1%E7%90%86.md "Transformers结合Trainer和WanDB实现训练日志管理"
