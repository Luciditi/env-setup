import { Hono } from 'hono'

const app = new Hono()
const base = 'env-setup'


app.get(`/${base}/:ver?`, async (c) => {
  const init_script = c.env.INIT_SCRIPT ?? "scripts/init"
  const ver = c.req.param('ver') ?? 'main'
  const repo = `${c.env.GITHUB_ORG}/${base}` ?? ''
  const token = c.env.GITHUB_TOKEN ?? ''
  const url = `https://api.github.com/repos/${repo}/contents/${init_script}`

  const req = await new Request(`https://api.github.com/repos/${repo}/contents/${init_script}`,{
    method: "GET",
    headers: {
      'Accept': 'application/vnd.github+json',
      'Authorization': `Bearer ${token}`,
      'User-Agent': 'env-setup',
      'X-GitHub-Api-Version': '2022-11-28',
    }
  })
  const x = await fetch(req)
    .then((res) => res.body)
    .then((body) => {
        const reader = body.getReader();
        return new ReadableStream({
          start(controller) {
            return pump();
            function pump() {
              return reader.read().then(({ done, value }) => {
                if (done) {
                  controller.close();
                  return;
                }
                controller.enqueue(value);
                return pump();
              });
            }
          },
        });
      })
      .then((stream) => new Response(stream))
      .then((response) => response.blob())
    .then((body) => {
      return body
    })
    .catch((error) => {
      console.log(`Could not serve ${url}`)
      console.log(error)
      return "X"
    })

  try {
    const scriptMeta = JSON.parse(await x.text())
    const script = atob(scriptMeta.content)
    return c.text(script)
  }
  catch (error) {
    console.log(`Could not serve ${url}`)
    console.log(error)
    return c.text(`#!/usr/bin/env bash

echo "Server Error"`)
  }
})

export default app
