# threshold
Threshold voting and execution for the IC

## Setting up the voter list

``` shell
dfx canister call threshold update 'vec {principal "'$(dfx identity get-principal)'"; principal "2vxsx-fae"}'
```

_Note_: above the first principal is the `dfx` identity, so that one can vote from the command line. The second identity is the Candid GUI's, so that it can also be used.

The first call to a fresh (after (re-)install) `threshold` canister can set the list of voter principals.
After that this must be done by proposals.

CAVEAT: if the initial voter list doesn't contain `threshold`'s principal, self-updates will be rejected as demonstrated in the next steps...

## Example Proposal

One can send an example proposal to `threshold` by
``` shell
dfx canister call threshold register '("haha", record {principal "rrkah-fqaaa-aaaaa-aaaaq-cai"; "accept"; vec {68; 73; 68; 76; 0; 1; 113; 4; 104; 97; 104; 97}})'
```
This will prepare the "haha" proposal which  when executed will `accept '"haha"'` on itself.
You'll see in the replica log that the proposal got executed by seeing
```
[Canister rrkah-fqaaa-aaaaa-aaaaq-cai] ("cannot authorise", rrkah-fqaaa-aaaaa-aaaaq-cai)
```
because the canister is not authorised to vote.

If you have set up the voters array to contain 2 principals, then you have to vote twice to see that error:
``` shell
dfx canister call threshold accept '"haha"'
dfx canister call threshold accept '"haha"'
```

-------------

Welcome to your new threshold project and to the internet computer development community. By default, creating a new project adds this README and some template files to your project directory. You can edit these template files to customize your project and to include your own code to speed up the development cycle.

To get started, you might want to explore the project directory structure and the default configuration file. Working with this project in your development environment will not affect any production deployment or identity tokens.

To learn more before you start working with threshold, see the following documentation available online:

- [Quick Start](https://sdk.dfinity.org/docs/quickstart/quickstart-intro.html)
- [SDK Developer Tools](https://sdk.dfinity.org/docs/developers-guide/sdk-guide.html)
- [Motoko Programming Language Guide](https://sdk.dfinity.org/docs/language-guide/motoko.html)
- [Motoko Language Quick Reference](https://sdk.dfinity.org/docs/language-guide/language-manual.html)
- [JavaScript API Reference](https://erxue-5aaaa-aaaab-qaagq-cai.raw.ic0.app)

If you want to start working on your project right away, you might want to try the following commands:

```bash
cd threshold/
dfx help
dfx canister --help
```

## Running the project locally

If you want to test your project locally, you can use the following commands:

```bash
# Starts the replica, running in the background
dfx start --background

# Deploys your canisters to the replica and generates your candid interface
dfx deploy
```

Once the job completes, your application will be available at `http://localhost:8000?canisterId={asset_canister_id}`.

Additionally, if you are making frontend changes, you can start a development server with

```bash
npm start
```

Which will start a server at `http://localhost:8080`, proxying API requests to the replica at port 8000.

### Note on frontend environment variables

If you are hosting frontend code somewhere without using DFX, you may need to make one of the following adjustments to ensure your project does not fetch the root key in production:

- set`NODE_ENV` to `production` if you are using Webpack
- use your own preferred method to replace `process.env.NODE_ENV` in the autogenerated declarations
- Write your own `createActor` constructor
