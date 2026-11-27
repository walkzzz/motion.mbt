// NLI —— natural language interface
// NLI frontend must produce MOT action sequences or ambiguity candidates.
// MOT is the structured output schema for LLM Function Calling.

///|
pub(all) struct AudioData {
  bytes : Array[Byte]
}

///|
pub(all) struct ImageData {
  bytes : Array[Byte]
  format : String
}

///|
pub(all) struct ExecutionContext {
  bodymap : BodyMapRef
  env_state : Map[String, Json]
  constraints : Array[String]
}

///|
pub(all) struct NLRequest {
  text : String?
  audio : AudioData?
  image : ImageData?
  context : ExecutionContext
}

///|
pub(all) enum NLI_Result {
  Success(TargetActionSeq)
  Ambiguous(Array[TargetActionSeq], Array[Double])
  Uninterpretable(String)
}

///|
pub(all) struct MOT_FunctionSchema {
  name : String
  description : String
  parameters : Json
  returns : Json
}
