String normalize(String value) {
  var result = value.toLowerCase().trim();
  const accents = {
    'á': 'a',
    'à': 'a',
    'â': 'a',
    'ã': 'a',
    'é': 'e',
    'ê': 'e',
    'í': 'i',
    'ó': 'o',
    'ô': 'o',
    'õ': 'o',
    'ú': 'u',
    'ç': 'c'
  };
  accents.forEach((a, b) {
    result = result.replaceAll(a, b);
  });
  return result;
}
