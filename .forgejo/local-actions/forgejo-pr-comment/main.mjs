import * as core from "@actions/core"

// retrieve inputs from environment
const inputs = {
  prNum: core.getInput("pr-num"),
  body: core.getInput("body"),
  comments: JSON.parse(core.getInput("comments")),
  apiUrl: process.env.FORGEJO_API_URL,
  repo: process.env.FORGEJO_REPOSITORY,
  authToken: process.env.FORGEJO_TOKEN,
};


// open a new review
core.info(`Starting a new review for PR ${inputs.prNum}`);
const respCreate = await fetch(`${inputs.apiUrl}/repos/${inputs.repo}/pulls/${inputs.prNum}/reviews`, {
  method: "POST",
  headers: {
    "Content-Type": "application/json",
    "Authorization": `Bearer ${inputs.authToken}`,
  },
  body: JSON.stringify({
    body: inputs.body,
    comments: inputs.comments.map(i => ({
      body: typeof i == "object" ? i.body : i,
      path: typeof i == "object" ? (i.path ?? null) : null,
    })),
  }),
});


// handle result
if (respCreate.ok) {
  const respCreateData = await respCreate.json();
  console.log(`Got success response from forgejo: ${JSON.stringify(respCreateData)}`)
  core.info(`Successfully created PR review ${respCreateData.id} with desired content`)
} else {
  core.error(`Request to ${respCreate.url} failed with status ${respCreate.status}: ${await respCreate.text()}`);
  core.setFailed("Could not add PR comment")
}
