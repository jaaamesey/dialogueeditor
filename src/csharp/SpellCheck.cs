using Godot;
using NHunspell;
using Godot.Collections;

public class SpellCheck : Node
{
	private static readonly Hunspell Hunspell = new Hunspell("en_UK.aff", "en_UK.dic");

	private static bool _realtimeEnabled = true;

	private static Dictionary _ignoredWords = new Dictionary();

	public class SpellCheckResult : Object
	{
		public readonly Control Block;
		public readonly int Index;
		public readonly string Word;

		public SpellCheckResult(Control block, int index, string word)
		{
			Block = block;
			Index = index;
			Word = word;
		}
	}

	public static void WarmUp()
	{
		for (var i = 0; i < 10; i++)
		{
			CheckString("According to all known laws of aviation, there is no way a bee should be able to fly.");
			CheckString(
				"Accorfding toa alal knfown lawzs owf aviatiaon, theare izs nno wway aa baee shouald bae ablae.");

			var test = CheckString("Thiz!  uwu iz sum? texxt tu vwarm upp da spiell chkear und makeed ita gud. :)");
			var spellCheckResult = new SpellCheckResult(new Control(), 8, "bepis");
			CheckBlocks(new Array<Control>());
		}
	}

	// Checks the TextEdits of the provided set of Dialogue Blocks for spelling errors.
	// Returns a Dictionary in the form {id : {index : word}}
	public static Array<SpellCheckResult> CheckBlocks(Array<Control> blocks)
	{
		var outputArr = new Array<SpellCheckResult>();
		foreach (var block in blocks)
		{
			var textEdit = (TextEdit) block.Get("dialogue_line_edit");
			var spellingErrors = CheckString(textEdit.Text);
			if (spellingErrors.Count > 0)
			{
				foreach (var indexWordPair in spellingErrors)
				{
					var spellCheckResult = new SpellCheckResult(block, indexWordPair.Key, indexWordPair.Value);
					outputArr.Add(spellCheckResult);
				}
			}
		}

		return outputArr;
	}


	// Checks a given string for spelling errors.
	// Returns a Dictionary in the form {index : word}
	public static Dictionary<int, string> CheckString(string input)
	{
		var outputDict = new Dictionary<int, string>();

		// For each character
		var currentWord = "";
		for (var i = 0; i < input.Length; i++)
		{
			var currentChar = input[i];

			// If at a space character or final character, current word is complete.
			var isLastCharacter = i >= input.Length - 1;

			if ((!char.IsLetterOrDigit(currentChar) && currentChar != '-' && currentChar != '\'') || isLastCharacter)
			{
				if (isLastCharacter && char.IsLetterOrDigit(currentChar))
					currentWord += currentChar;

				Hunspell.Spell(currentWord);

				// If word has incorrect spelling, add index and word to dictionary.
				if (!IsWordCorrect(currentWord))
					outputDict.Add(i, currentWord);


				// Clear and move onto next word
				currentWord = "";

				continue;
			}

			currentWord += currentChar;
		}

		return outputDict;
	}

	private static bool IsWordCorrect(string word)
	{
		// Initial check of word in raw state
		if (Hunspell.Spell(word)) return true;

		// Strip trailing hyphen
		if (word.EndsWith("-"))
			word = word.Remove(word.Length - 1, 1);

		// If in ignored words dictionary, return true
		if (_ignoredWords.ContainsKey(word.ToLower()))
			return true;

		// If still returning a spelling mistake after cleanup
		if (Hunspell.Spell(word) == false)
		{
			// Strip trailing 's' to allow plural acronyms
			if (word.EndsWith("s"))
				word = word.Remove(word.Length - 1, 1);


			// Ignore if word is all caps
			if (word == word.ToUpper())
				return true;

			return false;
		}

		return true;
	}

	private static void SetIgnoredWords(Dictionary dict)
	{
		_ignoredWords = dict;
	}

	private static void SetRealtimeEnabled(bool enabled)
	{
		_realtimeEnabled = enabled;
	}

	private static bool IsRealtimeEnabled()
	{
		return _realtimeEnabled;
	}
}