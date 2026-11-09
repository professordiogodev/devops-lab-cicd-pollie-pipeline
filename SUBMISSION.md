# Submission

Fork URL: <!-- paste the URL of your fork here -->

## Files to commit

- [ ] `.github/workflows/ci.yml`: your pipeline

## Questions

Answer in your own words. Where a question asks for output, paste it in a code block.

### Q1. Paste the URL of your last green run on `main` and the names of its jobs with their durations. Which jobs run in parallel and which wait for others (`needs:`), and why did you order them that way?

**Your answer:**

<!-- replace this line with your answer -->

### Q2. Your `test` job uses `services:` for PostgreSQL and Redis. Paste that block. Why `--health-cmd` on the services, why the host `localhost` in the URLs, and what would happen without the health check?

**Your answer:**

<!-- replace this line with your answer -->

### Q3. Paste the URL of the pull request where CI went red because of the vulnerable dependency, the failing step with the CVE lines, and the fix. Why does the `scan` job fail the build instead of just reporting, and what does `ignore-unfixed` change?

**Your answer:**

<!-- replace this line with your answer -->

### Q4. Show the `permissions:` of your workflow. Which job is the only one that can write packages, and what does the top-level `contents: read` protect you from if a third-party action is compromised?

**Your answer:**

<!-- replace this line with your answer -->

### Q5. Paste the `concurrency:` block and explain what happens when you push twice in a row to a pull request. Where did you use a cache, and how much time did it save (compare two runs)?

**Your answer:**

<!-- replace this line with your answer -->

### Q6. Paste the `docker pull` of the image you published and `docker image inspect` showing its tags. Which tags did you publish (commit SHA, `latest`, branch?) and why is `latest` alone a bad idea?

**Your answer:**

<!-- replace this line with your answer -->

### Q7. Why do pull requests from forks not get write permissions or secrets, and why does the publish job only run on `main`? What attack does this prevent?

**Your answer:**

<!-- replace this line with your answer -->

### Q8. Paste the output of `./verify.sh`. It must end with **ALL CHECKS PASSED**.

**Your answer:**

<!-- replace this line with your answer -->

### Q9. **Tear down.** Paste the output of `./verify-teardown.sh`. It must end with **TEARDOWN VERIFIED**.

**Your answer:**

<!-- replace this line with your answer -->
