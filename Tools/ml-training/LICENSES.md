# Dataset License Attribution — M8.4 Ingredient Parser

## strangetom/ingredient-parser

- **Repository**: https://github.com/strangetom/ingredient-parser
- **License**: MIT License
- **Used for**: Primary training data (81,316 sentences, 13 token-level labels)
- **Data format**: SQLite database with pre-tokenized sentences and labels

```
MIT License

Copyright (c) strangetom

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

## NYT/ingredient-phrase-tagger

- **Repository**: https://github.com/NYTimes/ingredient-phrase-tagger
- **License**: Apache License 2.0
- **Used for**: Supplementary training data (180,000 examples, sentence-level labels)
- **Data format**: CSV with 7 columns (index, input, name, qty, range_end, unit, comment)
- **Note**: strangetom already includes NYT data as one of its 5 sources. Sentence-level dedup applied to avoid duplicates.

```
Copyright 2015 The New York Times Company

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```

## In-App Attribution

The following text should be included in the app's acknowledgments/credits section:

> Ingredient parsing model trained on data from:
> - ingredient-parser by strangetom (MIT License)
> - ingredient-phrase-tagger by The New York Times Company (Apache 2.0 License)
