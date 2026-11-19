/// Synthetic transport response; never evidence of a live provider call.
Map<String, dynamic> subjectTutorFixture(Map request) => {
  'mode': 'subject_chat',
  'status': 'answered',
  'subject': request['subject'],
  'grade': request['grade'],
  'conversation_id': request['conversation_id'],
  'request_id': request['request_id'],
  'generation': {
    'provider': 'gemini',
    'model': 'gemini-3.1-flash-lite',
    'http_status': 200,
    'status': 'answered',
    'language': 'uz',
    'grounding': 'citations_and_quotes_checked_not_semantic_verification',
  },
  'evidence': [
    {
      'id': 'e1',
      'source_refs': [
        {
          'book_title': 'Hidden textbook',
          'printed_pages': [9],
        },
      ],
    },
  ],
  'paragraphs': [
    {
      'text': 'Sintetik suhbat javobi — haqiqiy AI sinovi emas.',
      'evidence_ids': ['e1'],
    },
  ],
};
