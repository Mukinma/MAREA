(() => {
  let detectorPromise;
  const translators = new Map();

  const isSupported = () =>
    'LanguageDetector' in globalThis && 'Translator' in globalThis;

  const getDetector = () => {
    detectorPromise ??= globalThis.LanguageDetector.create();
    detectorPromise.catch(() => {
      detectorPromise = undefined;
    });
    return detectorPromise;
  };

  const getTranslator = (sourceLanguage, targetLanguage) => {
    const key = `${sourceLanguage}:${targetLanguage}`;
    let translatorPromise = translators.get(key);
    if (!translatorPromise) {
      translatorPromise = globalThis.Translator.create({
        sourceLanguage,
        targetLanguage,
      });
      translators.set(key, translatorPromise);
      translatorPromise.catch(() => {
        translators.delete(key);
      });
    }
    return translatorPromise;
  };

  const translate = async (text, targetLanguage) => {
    if (!isSupported()) return { error: 'unsupported_language' };
    if (targetLanguage !== 'es' && targetLanguage !== 'en') {
      return { error: 'unsupported_language' };
    }

    try {
      const expectedSourceLanguage = targetLanguage === 'es' ? 'en' : 'es';
      const expectedTranslator = getTranslator(
        expectedSourceLanguage,
        targetLanguage,
      );
      const detector = await getDetector();
      const candidates = await detector.detect(text);
      const bestMatch = candidates[0];
      if (!bestMatch || bestMatch.confidence < 0.5) {
        return { error: 'language_undetermined' };
      }

      const sourceLanguage = bestMatch.detectedLanguage;
      if (sourceLanguage === targetLanguage) return { text };

      const translator = await (sourceLanguage === expectedSourceLanguage
        ? expectedTranslator
        : getTranslator(sourceLanguage, targetLanguage));
      return { text: await translator.translate(text) };
    } catch (error) {
      return {
        error: error?.name === 'NotSupportedError'
          ? 'unsupported_language'
          : 'model_unavailable',
      };
    }
  };

  globalThis.mareaLocalTranslationSupported = isSupported;
  globalThis.mareaTranslateLocally = async (text, targetLanguage) =>
    JSON.stringify(await translate(text, targetLanguage));
})();
