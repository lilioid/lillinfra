import * as core from "@actions/core"

// retrieve inputs from environment
const inputs = {
  target: core.getInput("target", { required: false }),
  src: core.getInput("src", { required: true }),
  title: core.getInput("title", { required: true }),
  body: core.getInput("body", { required: true }),
  allowUpdates: core.getBooleanInput("allow-updates", { required: false }),
};
const env = {
  api_url: process.env.FORGEJO_API_URL,
  repository: process.env.FORGEJO_REPOSITORY,
  auth_token: process.env.FORGEJO_TOKEN,
};

async function apiFetch(method, path, body) {
  return await fetch(`${env.api_url}${path}`, {
    method: method,
    headers: {
      "Authorization": `Bearer ${env.auth_token}`,
      Content-Type: "application/json"
    },
    body: body,
  })
}

// find pre-existing PR
core.debug("Searching for existing PR");
const respExisting = await fetch(`${ env.api_url }/repos/${ env.repository }/pulls/${ inputs.target }/${ inputs.src }`, {
  headers: {
    "Authorization": `Bearer ${ env.auth_token }`,
  },
});

if (respExisting.status == 200) {
  // update existing PR
  const dataExisting = await respExisting.json();
  core.info(`Updating existing PR ${ dataExisting.number }`)
  const updateResp = await fetch(`${ env.api_url }/repos/${ env.repository }/pulls/${ dataExisting.number }`, {
    method: "PATCH",
    headers: {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${ env.auth_token }`,
    },
    body: JSON.stringify({
      title: inputs.title,
      body: inputs.body,
    }),
  });
  if (updateResp.ok) {
    core.notice(`Updated PR ${dataExisting.number}`);
    core.setOutput("pr-num", dataExisting.number);
  } else {
    core.error(`Update-Request to ${updateResp.url} failed with status ${updateResp.status}: ${updateResp.statusText}: ${await updateResp.text()}`);
    core.setFailed(`Could not update existing PR ${ dataExisting.number }`);
  }
  
} else {
  // create new PR
  core.info("Creating new PR")
  const createResp = await fetch(`${ env.api_url }/repos/${ env.repository }/pulls`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${ env.auth_token }`,
    },
    body: JSON.stringify({
      base: inputs.target,
      head: inputs.src,
      title: inputs.title,
      body: inputs.body
    }),
  });
  if (createResp.ok) {
    const createData = await createResp.json();
    core.notice(`Created PR ${createData.number}`);
    core.setOutput("pr-num", createData.number);
  } else {
    core.error(`Update-Request to ${createResp.url} failed with status ${createResp.status}: ${createResp.statusText}: ${await createResp.text()}`);
    core.setFailed(`Could not create new PR`);
  }
}

