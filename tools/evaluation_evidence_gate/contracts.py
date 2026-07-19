"""Single source of truth for the evaluation-evidence-gate audit runner's JSONL field names.

Every JSONL producer and consumer in tools/evaluation_evidence_gate (the audit runner, the
judge prompt cross-check, and their tests) must reference these tuples
rather than re-typing field-name string literals, so a rename only ever
happens in one place.
"""

TURN_FIELDS = ("turn_id", "session_id", "timestamp", "turn_type", "final_text", "source_uuid")
VERDICT_FIELDS = ("turn_id", "verdict_present", "backed")
LABEL_FIELDS = ("turn_id", "is_unbacked_verdict", "turn_type")
TURN_TYPES = ("completion_claim", "hand_off", "question", "other")
