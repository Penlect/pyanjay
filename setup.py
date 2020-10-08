"""pyanjay build script"""

import os
import pathlib
from setuptools import setup, Extension, find_packages

with open('README.rst') as readme_file:
    long_description = readme_file.read()

# The package can't be imported at this point since the extension
# module does not exist yet. Therefore, we grab the metadata lines
# manually.
with open('pyanjay/__init__.py') as init:
    lines = [line for line in init.readlines() if line.startswith('__')]
exec(''.join(lines), globals())

def find_c_files(*dirs):
    output = list()
    for root in dirs:
        for path, _, files in os.walk(root):
            for f in files:
                if f.endswith('.c'):
                    output.append(os.path.join(path, f))
    return output

source_dirs = [
    'src',
    'Anjay/src',
    'Anjay/deps/avs_coap/src',
    'Anjay/deps/avs_commons/src',
]

c_files = find_c_files(*source_dirs)

include_dirs = source_dirs + [
    'include',
    'Anjay/example_configs/linux_lwm2m10',
    'Anjay/include_public',
    'Anjay/deps/avs_coap/include_public',
    'Anjay/deps/avs_commons/include_public'
]

anjaylibs = [
    'mbedtls',
    'mbedx509',
    'mbedcrypto'
]

ext_modules = [
    Extension(
        'pyanjay.anjay',
        sources=c_files + ['pyanjay/anjay.pyx'],
        include_dirs=include_dirs,
        libraries=anjaylibs,
    ),
    Extension(
        'pyanjay.dm',
        sources= c_files + ['pyanjay/dm.pyx'],
        include_dirs=include_dirs,
        libraries=anjaylibs,
    )
]

for e in ext_modules:
    e.cython_directives = {'language_level': '3'}

setup(
    name='pyanjay',
    version=__version__,
    author=__author__,
    author_email=__email__,
    description='Python binding for Anjay LwM2M library',
    long_description=long_description,
    license=__license__,
    keywords='lwm2m anjay',
    url=__url__,
    ext_modules=ext_modules,
    packages=find_packages(exclude=["test"]),
    include_package_data=True,
    zip_safe=False,
    setup_requires=[
        'setuptools>=18.0',
        'cython'
    ],
    test_suite="test",
    classifiers=[
        'Development Status :: 3 - Alpha',
        'Environment :: Console',
        'Intended Audience :: Developers',
        'Intended Audience :: Education',
        'Intended Audience :: Science/Research',
        'License :: OSI Approved :: MIT License',
        'Natural Language :: English',
        'Operating System :: POSIX :: Linux',
        'Operating System :: MacOS',
        'Operating System :: Microsoft :: Windows :: Windows 10',
        'Programming Language :: C',
        'Programming Language :: Python :: 3.7',
        'Programming Language :: Python :: 3.8',
        'Programming Language :: Python :: 3.9',
        'Programming Language :: Python :: Implementation :: CPython'
    ]
)
